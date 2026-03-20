local config = require("infracost.config")

local M = {}

function M.check()
  vim.health.start("infracost.nvim")

  -- Check infracost-ls binary
  local server_path = config.options.server_path or config.defaults.server_path
  if vim.fn.executable(server_path) == 1 then
    local version = vim.fn.system({ server_path, "--version" }):gsub("%s+$", "")
    vim.health.ok("infracost-ls found: " .. server_path .. " (" .. version .. ")")
  else
    vim.health.error("infracost-ls not found: " .. server_path, {
      "Install infracost-ls or set server_path in setup()",
    })
  end

  -- Check Neovim version
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.warn("Neovim 0.10+ recommended for inlay hints and vim.ui.open")
  end
end

return M
