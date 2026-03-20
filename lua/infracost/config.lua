local M = {}

---@class infracost.Config
---@field server_path string Path to infracost-ls binary
---@field cache_ttl number Cache TTL in seconds for run params
---@field debug_ui? string Host:port for the debug web UI (e.g. ":7100")

---@type infracost.Config
M.defaults = {
  server_path = "infracost-ls",
  cache_ttl = 300,
  debug_ui = nil,
}

---@type infracost.Config
M.options = vim.deepcopy(M.defaults)

---@param opts? infracost.Config
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
