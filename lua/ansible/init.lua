local M = {}

-- Configuration
local config = {
  playbooks_dir = "playbooks",
  environments_dir = "environments",
  cmd = "ansible-playbook", -- The ansible command to use (can be an alias)
  default_options = "", -- Additional options like --diff
  verbosity = 0, -- 0 = no verbosity, 1-5 = -v to -vvvvv
  reuse_terminal = false, -- Whether to reuse the same floaterm window
  recursive_playbooks = false, -- Search subdirectories in playbooks_dir
  recursive_environments = false, -- Search subdirectories in environments_dir
  float_opts = {
    relative = "editor",
    width = 80,
    height = 20,
    col = math.floor((vim.o.columns - 80) / 2),
    row = math.floor((vim.o.lines - 20) / 2),
    style = "minimal",
    border = "rounded"
  }
}

-- Store the last executed command
local last_command = nil

-- Store original user config to avoid re-applying project config
local user_config = nil

-- Load project-specific configuration
local function load_project_config()
  local cwd = vim.fn.getcwd()
  local config_file = cwd .. "/.ansible-nvim.lua"
  
  if vim.fn.filereadable(config_file) == 1 then
    local ok, project_config = pcall(dofile, config_file)
    if ok and type(project_config) == "table" then
      return project_config
    else
      vim.notify("Error loading project config: " .. config_file, vim.log.levels.WARN)
    end
  end
  
  return {}
end

-- Apply configuration with project overrides
local function apply_config()
  if not user_config then
    return
  end
  
  local project_config = load_project_config()
  config = vim.tbl_deep_extend("force", config, user_config, project_config)
end

-- Helper function to check if directory exists
local function dir_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "directory"
end

-- Helper function to get files from directory (with optional recursive search)
local function get_files(dir, extension, recursive)
  local files = {}
  if not dir_exists(dir) then
    return files
  end
  
  local function scan_dir(path, prefix)
    local handle = vim.loop.fs_scandir(path)
    if handle then
      while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then break end
        
        local full_path = path .. "/" .. name
        local relative_path = prefix and (prefix .. "/" .. name) or name
        
        if type == "file" and (not extension or name:match("%." .. extension .. "$")) then
          table.insert(files, relative_path)
        elseif type == "directory" and recursive then
          scan_dir(full_path, relative_path)
        end
      end
    end
  end
  
  scan_dir(dir, nil)
  return files
end

-- Helper function to extract tags from playbook
local function get_playbook_tags(playbook_path)
  local tags = {}
  local file = io.open(playbook_path, "r")
  if not file then return tags end
  
  local content = file:read("*all")
  file:close()
  
  -- Simple regex to find tags in YAML
  for tag in content:gmatch("tags:%s*([%w_-]+)") do
    if not vim.tbl_contains(tags, tag) then
      table.insert(tags, tag)
    end
  end
  
  for tag in content:gmatch("tags:%s*%[([^%]]+)%]") do
    for t in tag:gmatch("([%w_-]+)") do
      if not vim.tbl_contains(tags, t) then
        table.insert(tags, t)
      end
    end
  end
  
  return tags
end

-- Helper function to get relative path from project root
local function get_relative_path(filepath)
  local cwd = vim.fn.getcwd()
  if filepath:sub(1, #cwd) == cwd then
    return filepath:sub(#cwd + 2) -- +2 to remove leading slash
  end
  return filepath
end

-- Helper function to check if file is in specific directory
local function is_file_in_dir(filepath, dir)
  local relative_path = get_relative_path(filepath)
  return relative_path:match("^" .. dir .. "/")
end

-- Helper function to extract filename from path
local function get_filename(filepath)
  return filepath:match("([^/]+)$")
end

-- Telescope picker for file selection
local function create_picker(items, prompt, callback)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  
  pickers.new({}, {
    prompt_title = prompt,
    finder = finders.new_table({
      results = items
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          callback(selection[1])
        end
      end)
      return true
    end,
  }):find()
end

-- Custom centered input function using floating window
local function get_input(prompt, callback, default)
  local width = math.min(80, vim.o.columns - 4)
  local height = 3
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  -- Create the floating window
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Input ",
    title_pos = "center"
  })
  
  -- Set up the buffer content
  local prompt_line = prompt
  local input_line = default or ""
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    prompt_line,
    input_line,
    ""
  })
  
  -- Position cursor at end of input line
  vim.api.nvim_win_set_cursor(win, {2, #input_line})
  
  -- Set up keymaps
  local function close_and_callback(result)
    vim.api.nvim_win_close(win, true)
    if result ~= nil then
      callback(result)
    end
  end
  
  -- Enter to confirm
  vim.keymap.set("i", "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local input = lines[2] or ""
    close_and_callback(input)
  end, { buffer = buf })
  
  vim.keymap.set("n", "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local input = lines[2] or ""
    close_and_callback(input)
  end, { buffer = buf })
  
  -- Escape to cancel
  vim.keymap.set({"i", "n"}, "<Esc>", function()
    close_and_callback(nil)
  end, { buffer = buf })
  
  -- q to cancel in normal mode
  vim.keymap.set("n", "q", function()
    close_and_callback(nil)
  end, { buffer = buf })
  
  -- Start in insert mode on the input line
  vim.cmd("startinsert")
  vim.api.nvim_win_set_cursor(win, {2, #input_line})
end

-- Function to run ansible command in floaterm
local function run_ansible_command(command)
  -- Check if floaterm is available
  if vim.fn.exists(":FloatermNew") == 0 then
    vim.notify("floaterm plugin not found. Please install it.", vim.log.levels.ERROR)
    return
  end
  
  -- Store the command for potential re-run
  last_command = command
  
  if config.reuse_terminal then
    -- Check if ansible terminal already exists
    local existing_terminals = vim.fn["floaterm#terminal#get_bufnr"]("ansible")
    
    if existing_terminals ~= -1 then
      -- Terminal exists, show it and send the command
      vim.cmd("FloatermShow ansible")
      vim.cmd("FloatermSend --name=ansible " .. command)
    else
      -- Create new persistent terminal without running command immediately
      vim.cmd("FloatermNew --name=ansible --title=ansible")
      -- Send the command to the new terminal
      vim.cmd("FloatermSend --name=ansible " .. command)
    end
  else
    -- Create new terminal each time (original behavior)
    vim.cmd("FloatermNew --title=ansible " .. command)
  end
end

-- Function to run the last executed command
local function run_ansible_last()
  if not last_command then
    vim.notify("No previous Ansible command found. Run a playbook first.", vim.log.levels.WARN)
    return
  end
  
  vim.notify("Re-running last command: " .. last_command, vim.log.levels.INFO)
  run_ansible_command(last_command)
end

-- Function to handle tag selection and continue workflow  
local function proceed_with_tags(playbook, playbook_path, inventory)
  local inventory_path = config.environments_dir .. "/" .. inventory
  
  -- Step 3: Check for tags
  local tags = get_playbook_tags(playbook_path)
  
  local function continue_with_limits(selected_tag)
    -- Step 4: Get limit input
    get_input("Limit to hosts/groups (comma-separated, leave empty for all): ", function(limit)
      -- Step 5: Get extra variables
      get_input("Extra variables (key=value,key2=value2, leave empty for none): ", function(extra_vars)
        -- Step 6: Get dry-run option
        get_input("Dry run? (y/N): ", function(dry_run)
          -- Build ansible command
          local cmd = config.cmd
          cmd = cmd .. " -i " .. inventory_path
          
          -- Add verbosity
          if config.verbosity > 0 and config.verbosity <= 5 then
            cmd = cmd .. " -" .. string.rep("v", config.verbosity)
          end
          
          -- Add default options
          if config.default_options and config.default_options ~= "" then
            cmd = cmd .. " " .. config.default_options
          end
          
          cmd = cmd .. " " .. playbook_path
          
          if selected_tag and selected_tag ~= "" then
            cmd = cmd .. " --tags " .. selected_tag
          end
          
          if limit and limit ~= "" then
            cmd = cmd .. " --limit " .. limit
          end
          
          -- Add extra variables
          if extra_vars and extra_vars ~= "" then
            for var in extra_vars:gmatch("([^,]+)") do
              local trimmed = var:match("^%s*(.-)%s*$") -- trim whitespace
              if trimmed ~= "" then
                cmd = cmd .. " -e " .. trimmed
              end
            end
          end
          
          -- Add dry-run option
          if dry_run and (dry_run:lower() == "y" or dry_run:lower() == "yes") then
            cmd = cmd .. " --check"
          end
          
          -- Run the command
          run_ansible_command(cmd)
        end)
      end)
    end)
  end
  
  if not vim.tbl_isempty(tags) then
    -- Add option to run all tasks
    table.insert(tags, 1, "all")
    create_picker(tags, "Select Tag (or 'all' for no tag filtering)", function(tag)
      local selected_tag = (tag == "all") and "" or tag
      continue_with_limits(selected_tag)
    end)
  else
    continue_with_limits(nil)
  end
end

-- Function to handle inventory selection and continue workflow
local function proceed_with_inventory(playbook, preselected_inventory)
  local playbook_path = config.playbooks_dir .. "/" .. playbook
  
  -- Step 2: Get inventories (skip if already selected from current buffer)
  if preselected_inventory then
    proceed_with_tags(playbook, playbook_path, preselected_inventory)
  else
    local inventories = get_files(config.environments_dir, nil, config.recursive_environments)
    if vim.tbl_isempty(inventories) then
      vim.notify("No inventories found in " .. config.environments_dir, vim.log.levels.ERROR)
      return
    end
    
    create_picker(inventories, "Select Inventory", function(inventory)
      proceed_with_tags(playbook, playbook_path, inventory)
    end)
  end
end

-- Main function to run the ansible workflow
local function run_ansible(use_current_buffer)
  local current_file = nil
  local selected_playbook = nil
  local selected_inventory = nil
  
  -- Check current buffer if requested
  if use_current_buffer then
    current_file = vim.api.nvim_buf_get_name(0)
    if current_file and current_file ~= "" then
      if is_file_in_dir(current_file, config.playbooks_dir) then
        selected_playbook = get_filename(current_file)
        vim.notify("Using current playbook: " .. selected_playbook, vim.log.levels.INFO)
      elseif is_file_in_dir(current_file, config.environments_dir) then
        selected_inventory = get_filename(current_file)
        vim.notify("Using current inventory: " .. selected_inventory, vim.log.levels.INFO)
      end
    end
  end
  
  -- Step 1: Get playbooks (skip if already selected from current buffer)
  if selected_playbook then
    proceed_with_inventory(selected_playbook, selected_inventory)
  else
    local playbooks = get_files(config.playbooks_dir, "yml", config.recursive_playbooks)
    if vim.tbl_isempty(playbooks) then
      playbooks = get_files(config.playbooks_dir, "yaml", config.recursive_playbooks)
    end
    
    if vim.tbl_isempty(playbooks) then
      vim.notify("No playbooks found in " .. config.playbooks_dir, vim.log.levels.ERROR)
      return
    end
    
    create_picker(playbooks, "Select Playbook", function(playbook)
      proceed_with_inventory(playbook, selected_inventory)
    end)
  end
end

-- Setup function
function M.setup(opts)
  user_config = opts or {}
  config = vim.tbl_deep_extend("force", config, user_config)
  
  -- Apply any project-specific config
  apply_config()
  
  -- Create user commands
  vim.api.nvim_create_user_command("AnsibleRun", function() run_ansible(false) end, {})
  vim.api.nvim_create_user_command("AnsibleRunCurrent", function() run_ansible(true) end, {})
  vim.api.nvim_create_user_command("AnsibleRunLast", run_ansible_last, {})
  
  -- Set up keybindings
  vim.keymap.set("n", "<leader>ap", function() run_ansible(false) end, { 
    desc = "Run Ansible Playbook",
    silent = true 
  })
  
  vim.keymap.set("n", "<leader>ac", function() run_ansible(true) end, { 
    desc = "Run Ansible with Current Buffer",
    silent = true 
  })
  
  vim.keymap.set("n", "<leader>ar", run_ansible_last, { 
    desc = "Re-run Last Ansible Command",
    silent = true 
  })
  
  -- Set up autocmd to reload config when changing directories
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("AnsibleProjectConfig", { clear = true }),
    callback = function()
      apply_config()
    end,
    desc = "Reload ansible.nvim project configuration"
  })
end

-- Export the run functions for direct use
M.run = function() run_ansible(false) end
M.run_current = function() run_ansible(true) end
M.run_last = run_ansible_last

return M
