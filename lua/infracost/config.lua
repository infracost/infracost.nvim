local M = {}

---@class infracost.Config
---@field server_path string Path to infracost-ls binary
---@field cache_ttl number Cache TTL in seconds for run params
---@field debug_ui? string Host:port for the debug web UI (e.g. ":7100")
---@field enable_bicep boolean Estimate Bicep files (requires the Bicep CLI on PATH)

---@type infracost.Config
M.defaults = {
  server_path = "infracost-ls",
  cache_ttl = 300,
  debug_ui = nil,
  -- Off by default: estimating a Bicep file compiles it, which downloads any
  -- modules it references from their registries. User-level by construction --
  -- this option only exists in the user's own setup() call, so there is no
  -- project-local file a repository could use to switch it on.
  enable_bicep = false,
}

---@type infracost.Config
M.options = vim.deepcopy(M.defaults)

---@param opts? infracost.Config
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
