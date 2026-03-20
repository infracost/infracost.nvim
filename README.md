# infracost.nvim

Neovim plugin for [Infracost](https://www.infracost.io/) — see cloud cost estimates and FinOps policy checks inline as you write infrastructure code.

![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-green?logo=neovim)

https://github.com/user-attachments/assets/3e12da93-52ac-45c5-bf04-7603f96f1aad


## Features

- **Inline cost estimates** — code lenses show monthly cost above each resource
- **Hover details** — full cost component breakdown on hover
- **Diagnostics** — FinOps policy violations and tag issues in the gutter
- **Code actions** — quick fixes and dismiss actions for violations
- **Resource panel** — sidebar with detailed cost breakdown for the resource under cursor
- **Login** — OAuth device flow from within Neovim

Supports Terraform (`.tf`, `.hcl`) and CloudFormation (YAML/JSON).

## Requirements

- Neovim >= 0.10
- [infracost-ls](https://github.com/infracost/infracost) on your `$PATH`

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "infracost/infracost.nvim",
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "infracost/infracost.nvim",
  config = function()
    require("infracost").setup()
  end,
}
```

## Configuration

Default options:

```lua
require("infracost").setup({
  server_path = "infracost-ls", -- path to infracost-ls binary
  cache_ttl = 300,              -- cache TTL in seconds
  debug = false,                -- enable LSP trace logging
})
```

## Commands

| Command                 | Description                         |
| ----------------------- | ----------------------------------- |
| `:InfracostTogglePanel` | Toggle the resource details sidebar |
| `:InfracostLogin`       | Log in to Infracost                 |
| `:InfracostRestartLsp`  | Restart the language server         |

## Keymaps

No keymaps are set by default. Suggested mappings:

```lua
vim.keymap.set("n", "<leader>ic", "<cmd>InfracostTogglePanel<cr>", { desc = "Toggle Infracost panel" })
vim.keymap.set("n", "<leader>il", "<cmd>InfracostLogin<cr>", { desc = "Infracost login" })
```

## Health Check

Run `:checkhealth infracost` to verify your setup.

## License

Apache-2.0
