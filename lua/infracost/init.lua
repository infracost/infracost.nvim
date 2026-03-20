local config = require("infracost.config")
local lsp = require("infracost.lsp")
local login = require("infracost.login")
local resource_panel = require("infracost.resource_panel")

local M = {}

---@param opts? infracost.Config
function M.setup(opts)
  config.setup(opts)

  -- Register client-side LSP commands
  lsp.register_commands()

  -- Commands
  vim.api.nvim_create_user_command("InfracostLogin", login.login, {})
  vim.api.nvim_create_user_command("InfracostRestartLsp", lsp.restart, {})
  vim.api.nvim_create_user_command("InfracostTogglePanel", resource_panel.toggle, {})

  -- Auto-attach LSP on supported file types
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "terraform", "hcl", "yaml", "json" },
    callback = function()
      lsp.attach()
    end,
  })
end

return M
