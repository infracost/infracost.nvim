local util = require("infracost.util")

local M = {}

local panel_buf = nil
local panel_win = nil
local ns = vim.api.nvim_create_namespace("infracost_panel")

--- Check if the panel window is open and valid.
---@return boolean
function M.is_open()
  return panel_win ~= nil and vim.api.nvim_win_is_valid(panel_win)
end

local is_open = M.is_open

--- Create or focus the panel buffer.
local function ensure_panel()
  if panel_buf == nil or not vim.api.nvim_buf_is_valid(panel_buf) then
    panel_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[panel_buf].buftype = "nofile"
    vim.bo[panel_buf].filetype = "infracost"
    vim.bo[panel_buf].bufhidden = "hide"
  end

  if not is_open() then
    vim.cmd("botright vsplit")
    panel_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(panel_win, panel_buf)
    vim.api.nvim_win_set_width(panel_win, 50)
    vim.wo[panel_win].number = false
    vim.wo[panel_win].relativenumber = false
    vim.wo[panel_win].signcolumn = "no"
    vim.wo[panel_win].winfixwidth = true
    vim.wo[panel_win].wrap = true
    vim.wo[panel_win].linebreak = true
    vim.cmd("wincmd p") -- return to previous window
  end
end

--- Set panel content lines.
---@param lines string[]
---@param highlights? {line: number, hl: string}[]
local function set_content(lines, highlights)
  if panel_buf == nil or not vim.api.nvim_buf_is_valid(panel_buf) then
    return
  end
  vim.bo[panel_buf].modifiable = true
  vim.api.nvim_buf_set_lines(panel_buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(panel_buf, ns, 0, -1)
  for _, hl in ipairs(highlights or {}) do
    vim.api.nvim_buf_add_highlight(panel_buf, ns, hl.hl, hl.line, 0, -1)
  end
  vim.bo[panel_buf].modifiable = false
end

--- Format a resource details response into lines + highlights.
---@param result table
---@return string[], {line: number, hl: string}[]
local function format_resource(result)
  local lines = {}
  local highlights = {}

  if result.scanning then
    return { "  Scanning..." }, {}
  end

  if result.needsLogin then
    return { "  Login required.", "", "  Run :InfracostLogin" }, {}
  end

  local r = result.resource
  if not r then
    return { "  No resource selected." }, {}
  end

  -- Header
  table.insert(lines, "  " .. (r.name or ""))
  table.insert(highlights, { line = #lines - 1, hl = "Title" })
  table.insert(lines, "  " .. (r.type or ""))
  table.insert(highlights, { line = #lines - 1, hl = "Comment" })
  table.insert(lines, "")
  table.insert(lines, "  Monthly Cost: " .. (r.monthlyCost or "$0.00"))
  table.insert(highlights, { line = #lines - 1, hl = "String" })
  table.insert(lines, "")

  -- Cost components
  if r.costComponents and #r.costComponents > 0 then
    table.insert(lines, "  Cost Breakdown")
    table.insert(highlights, { line = #lines - 1, hl = "Title" })
    table.insert(lines, string.rep("─", 48))

    for _, c in ipairs(r.costComponents) do
      table.insert(lines, string.format("  %-28s %s", c.name or "", c.monthlyCost or ""))
      if c.unit and c.unit ~= "" then
        table.insert(lines, string.format("    %s × %s", c.monthlyQuantity or "", c.unit or ""))
        table.insert(highlights, { line = #lines - 1, hl = "Comment" })
      end
    end
    table.insert(lines, "")
  end

  -- FinOps violations
  if r.violations and #r.violations > 0 then
    table.insert(lines, string.format("  FinOps Issues (%d)", #r.violations))
    table.insert(highlights, { line = #lines - 1, hl = "DiagnosticWarn" })
    table.insert(lines, string.rep("─", 48))

    for _, v in ipairs(r.violations) do
      local prefix = v.blockPullRequest and "[BLOCKING] " or ""
      table.insert(lines, "  " .. prefix .. (v.policyName or ""))
      if v.blockPullRequest then
        table.insert(highlights, { line = #lines - 1, hl = "DiagnosticError" })
      else
        table.insert(highlights, { line = #lines - 1, hl = "DiagnosticWarn" })
      end
      table.insert(lines, "    " .. (v.message or ""))
      if v.monthlySavings and v.monthlySavings ~= "" then
        table.insert(lines, "    Potential savings: " .. v.monthlySavings .. "/mo")
        table.insert(highlights, { line = #lines - 1, hl = "String" })
      end
      table.insert(lines, "")
    end
  end

  -- Tag violations
  if r.tagViolations and #r.tagViolations > 0 then
    table.insert(lines, string.format("  Tag Issues (%d)", #r.tagViolations))
    table.insert(highlights, { line = #lines - 1, hl = "DiagnosticWarn" })
    table.insert(lines, string.rep("─", 48))

    for _, v in ipairs(r.tagViolations) do
      table.insert(lines, "  " .. (v.policyName or ""))
      table.insert(lines, "    " .. (v.message or ""))
      if v.missingTags and #v.missingTags > 0 then
        table.insert(lines, "    Missing: " .. table.concat(v.missingTags, ", "))
      end
      if v.invalidTags and #v.invalidTags > 0 then
        for _, t in ipairs(v.invalidTags) do
          table.insert(lines, string.format("    Invalid: %s=%s", t.key or "", t.value or ""))
        end
      end
      table.insert(lines, "")
    end
  end

  return lines, highlights
end

--- Fetch and display resource details for the current cursor position.
function M.update()
  local clients = vim.lsp.get_clients({ name = "infracost" })
  if #clients == 0 or not is_open() then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local uri = vim.uri_from_bufnr(bufnr)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed

  clients[1]:request("infracost/resourceDetails", { uri = uri, line = line }, function(err, result)
    if err or not result then
      return
    end
    vim.schedule(function()
      local lines, highlights = format_resource(result)
      set_content(lines, highlights)
    end)
  end)
end

--- Toggle the resource details panel.
function M.toggle()
  if is_open() then
    vim.api.nvim_win_close(panel_win, true)
    panel_win = nil
  else
    ensure_panel()
    set_content({ "  No resource selected." })
    M.update()
  end
end

--- Open the panel and show details for a specific uri + line.
---@param uri string
---@param line number 0-indexed line number
function M.show_for(uri, line)
  ensure_panel()

  local clients = vim.lsp.get_clients({ name = "infracost" })
  if #clients == 0 then
    set_content({ "  Infracost LSP not running." })
    return
  end

  set_content({ "  Loading..." })
  clients[1]:request("infracost/resourceDetails", { uri = uri, line = line }, function(err, result)
    if err or not result then
      return
    end
    vim.schedule(function()
      local lines, highlights = format_resource(result)
      set_content(lines, highlights)
    end)
  end)
end

--- Close the panel.
function M.close()
  if is_open() then
    vim.api.nvim_win_close(panel_win, true)
  end
  panel_win = nil
end

return M
