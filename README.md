# ansible.nvim

A Neovim plugin for running Ansible playbooks directly from your editor with fuzzy finding and floaterm integration.

## Features

- 🔍 Fuzzy searchable playbook selection from `playbooks/` directory
- 🌐 Fuzzy searchable inventory selection from `environments/` directory  
- 🏷️ Tag selection for playbooks that contain tags
- 🎯 Host/group limiting with `--limit` parameter
- 🖥️ Execution in floaterm for better terminal management
- 🔧 Configurable default options (e.g., `--diff`)
- 📊 Configurable verbosity levels (1-5 for -v to -vvvvv)
- 🔑 Extra variables support with `-e key=value`
- 🧪 Dry-run option with `--check`
- 📍 Centered input prompts for better UX
- 🎯 Smart current buffer detection (`:AnsibleRunCurrent` / `<leader>ac`)
- 📂 Auto-selects playbook or inventory based on current file
- 🔄 Falls back to full workflow if current file isn't recognized
- 🔄 Re-run last command (`:AnsibleRunLast` / `<leader>ar`)
- 💾 Automatic command history tracking
- 🔄 Configurable terminal reuse for persistent floaterm windows
- ⌨️ Configurable keybindings (default: `<leader>ap`, `<leader>ac`, and `<leader>ar`)

## Dependencies

Required plugins:
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - For fuzzy finding
- [floaterm](https://github.com/voldikss/vim-floaterm) - For terminal execution

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "MasterOfTheJuice/ansible.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "voldikss/vim-floaterm"
  },
  config = function()
    require("ansible").setup({
      -- Optional configuration
      playbooks_dir = "playbooks",      -- Directory containing playbooks
      environments_dir = "environments", -- Directory containing inventories
    })
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "MasterOfTheJuice/ansible.nvim",
  requires = {
    "nvim-telescope/telescope.nvim",
    "voldikss/vim-floaterm"
  },
  config = function()
    require("ansible").setup()
  end
}
```

## Usage

### Standard Workflow
1. Press `<leader>ap` or run `:AnsibleRun`
2. Select a playbook from the fuzzy finder
3. Select an inventory/environment
4. If the playbook has tags, select a tag (or "all" to skip tag filtering)
5. Optionally specify hosts/groups to limit execution to
6. Optionally specify extra variables as `key=value,key2=value2`
7. Choose whether to run in dry-run mode (`--check`)
8. The playbook will run in a new floaterm window

### Smart Current Buffer Workflow
1. Open a playbook (`.yml`/`.yaml` in `playbooks/`) or inventory file (in `environments/`)
2. Press `<leader>ac` or run `:AnsibleRunCurrent`
3. If current file is a **playbook**: automatically selects it, prompts for inventory
4. If current file is an **inventory**: automatically selects it, prompts for playbook  
5. If current file is **neither**: runs the full standard workflow
### Re-run Last Command
1. After running any ansible command via the plugin
2. Press `<leader>ar` or run `:AnsibleRunLast` 
3. The exact same command will re-execute immediately
4. No prompts, no selections - instant execution
5. Shows notification with the command being re-run

## Configuration

### Global Configuration

```lua
require("ansible").setup({
  playbooks_dir = "playbooks",        -- Default: "playbooks"
  environments_dir = "environments",   -- Default: "environments"
  cmd = "ansible-playbook",           -- Default: "ansible-playbook" (can use alias)
  default_options = "--diff",          -- Default: "" (additional options)
  verbosity = 1,                      -- Default: 0 (0=none, 1=-v, 2=-vv, etc.)
  reuse_terminal = true,              -- Default: false (reuse floaterm window)
  float_opts = {                      -- Telescope floating window options
    relative = "editor",
    width = 80,
    height = 20,
    col = math.floor((vim.o.columns - 80) / 2),
    row = math.floor((vim.o.lines - 20) / 2),
    style = "minimal",
    border = "rounded"
  }
})
```

### Project-specific Configuration

You can override configuration on a per-project basis by creating a `.ansible-nvim.lua` file in your project root:

```lua
-- .ansible-nvim.lua
return {
  cmd = "ap",                          -- Use project-specific alias
  default_options = "--vault-password-file .vault-pass --diff",
  verbosity = 2,                       -- More verbose for this project
  playbooks_dir = "ansible/playbooks", -- Different directory structure
  environments_dir = "ansible/inventories"
}
```

The plugin will automatically detect and load this configuration when you change directories. Project configuration takes precedence over global configuration.

## Directory Structure

Your project should have the following structure:

```
your-project/
├── playbooks/
│   ├── deploy.yml
│   ├── maintenance.yml
│   └── setup.yml
├── environments/
│   ├── production
│   ├── staging
│   └── development
└── ...
```

## Commands

- `:AnsibleRun` - Start the ansible playbook selection workflow
- `:AnsibleRunCurrent` - Smart workflow using current buffer context
- `:AnsibleRunLast` - Re-run the last executed ansible command

## Keybindings

- `<leader>ap` - Run ansible playbook (standard workflow)
- `<leader>ac` - Run ansible with current buffer context
- `<leader>ar` - Re-run last ansible command

You can customize the keybindings:

```lua
-- In your init.lua after setup
vim.keymap.set("n", "<leader>aa", require("ansible").run, { desc = "Run Ansible" })
vim.keymap.set("n", "<leader>aac", require("ansible").run_current, { desc = "Run Ansible Current" })
vim.keymap.set("n", "<leader>aal", require("ansible").run_last, { desc = "Run Ansible Last" })
```

## License

MIT
