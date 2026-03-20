local config = require("infracost.config")
local util = require("infracost.util")

local M = {}

local version = "0.1.0"

--- Handle the infracost.revealResource client-side command (from code lens clicks).
---@param command lsp.Command
local function reveal_resource(command)
  local args = command.arguments or {}
  if not args[1] or not args[2] then
    return
  end
  local resource_panel = require("infracost.resource_panel")
  resource_panel.show_for(args[1], args[2])
end

--- Get the LSP client config for infracost-ls.
---@return vim.lsp.ClientConfig
local function client_config()
  return {
    name = "infracost",
    cmd = { config.options.server_path },
    cmd_env = config.options.debug_ui and { INFRACOST_DEBUG_UI = config.options.debug_ui } or nil,
    root_dir = vim.fs.root(0, { ".terraform", ".terraform.lock.hcl", "infracost.yml", ".git" }) or vim.fn.getcwd(),
    init_options = {
      clientName = "neovim",
      extensionVersion = version,
      supportsCodeLens = true,
    },
    settings = {
      runParamsCacheTTLSeconds = config.options.cache_ttl,
    },
    handlers = {
      ["infracost/scanComplete"] = function()
        vim.lsp.codelens.refresh()
      end,
    },
    on_attach = function(client, bufnr)
      if client.supports_method("textDocument/codeLens") then
        vim.lsp.codelens.refresh({ bufnr = bufnr })

        vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
          buffer = bufnr,
          callback = function()
            vim.lsp.codelens.refresh({ bufnr = bufnr })
          end,
        })
      end

      if client.supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end

      -- Debounced resource panel update on cursor move
      vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = bufnr,
        callback = function()
          local resource_panel = require("infracost.resource_panel")
          util.debounce("resource_panel", 200, resource_panel.update)
        end,
      })

      vim.keymap.set("n", "<leader>ic", function()
        local resource_panel = require("infracost.resource_panel")
        if resource_panel.is_open() then
          resource_panel.close()
        else
          local uri = vim.uri_from_bufnr(bufnr)
          local line = vim.api.nvim_win_get_cursor(0)[1] - 1
          resource_panel.show_for(uri, line)
        end
      end, { buffer = bufnr, desc = "Toggle Infracost panel" })
    end,
  }
end

--- Register client-side commands. Called once during setup.
function M.register_commands()
  vim.lsp.commands["infracost.revealResource"] = reveal_resource
end

--- Attach infracost-ls to the current buffer if it's a supported file.
function M.attach()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" or not util.is_supported_file(bufname) then
    return
  end

  vim.lsp.start(client_config(), { bufnr = 0 })
end

--- Stop all infracost LSP clients.
function M.stop()
  local clients = vim.lsp.get_clients({ name = "infracost" })
  for _, client in ipairs(clients) do
    client:stop()
  end
end

--- Restart the infracost LSP client.
function M.restart()
  M.stop()
  vim.defer_fn(function()
    M.attach()
  end, 500)
end

return M
