# ansible.nvim

A Neovim plugin for running Ansible playbooks directly from your editor with fuzzy finding and floaterm integration.

## Features

- 🔍 Fuzzy searchable playbook selection from `playbooks/` directory
- 🌐 Fuzzy searchable inventory selection from `environments/` directory  
- 🏷️ Tag selection for playbooks that contain tags
- 🎯 Host/group limiting with `--limit` parameter
- 🖥️ Execution in floaterm for better terminal management
- ⌨️ Configurable keybindings (default: `<leader>ap`)

## Dependencies

Required plugins:
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - For fuzzy finding
- [floaterm](https://github.com/voldikss/vim-floaterm) - For terminal execution

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/ansible.nvim",
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
  "your-username/ansible.nvim",
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

1. Press `<leader>ap` or run `:AnsibleRun`
2. Select a playbook from the fuzzy finder
3. Select an inventory/environment
4. If the playbook has tags, select a tag (or "all" to skip tag filtering)
5. Optionally specify hosts/groups to limit execution to
6. The playbook will run in a new floaterm window

## Configuration

```lua
require("ansible").setup({
  playbooks_dir = "playbooks",        -- Default: "playbooks"
  environments_dir = "environments",   -- Default: "environments"
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

## Keybindings

- `<leader>ap` - Run ansible playbook (default)

You can customize the keybinding:

```lua
-- In your init.lua after setup
vim.keymap.set("n", "<leader>ar", require("ansible").run, { desc = "Run Ansible" })
```

## License

MIT
