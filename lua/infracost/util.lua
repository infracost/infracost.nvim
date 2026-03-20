local M = {}

---@type table<string, uv_timer_t>
local timers = {}

--- Debounce a function call by key.
---@param key string
---@param ms number
---@param fn function
function M.debounce(key, ms, fn)
  if timers[key] then
    timers[key]:stop()
  else
    timers[key] = vim.uv.new_timer()
  end
  timers[key]:start(ms, 0, vim.schedule_wrap(fn))
end

--- Check if a file is a supported IaC file.
---@param filename string
---@return boolean
function M.is_supported_file(filename)
  if filename:match("%.tf$") or filename:match("%.hcl$") then
    return true
  end

  if filename:match("%.ya?ml$") or filename:match("%.json$") then
    local basename = vim.fn.fnamemodify(filename, ":t"):lower()
    for _, pattern in ipairs({ "template", "cloudformation", "cfn", "stack", "infracost" }) do
      if basename:find(pattern, 1, true) then
        return true
      end
    end
  end

  return false
end

return M
