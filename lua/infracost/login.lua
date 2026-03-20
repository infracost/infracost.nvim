local M = {}

--- Initiate the Infracost OAuth device login flow.
function M.login()
  local clients = vim.lsp.get_clients({ name = "infracost" })
  if #clients == 0 then
    vim.notify("Infracost LSP not running", vim.log.levels.WARN)
    return
  end

  local client = clients[1]
  client:request("infracost/login", {}, function(err, result)
    if err then
      vim.notify("Login failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    if not result or not result.verificationUriComplete then
      vim.notify("Login failed: no verification URI returned", vim.log.levels.ERROR)
      return
    end

    local msg = string.format(
      "Open the following URL to log in:\n%s\n\nCode: %s",
      result.verificationUriComplete,
      result.userCode or ""
    )

    vim.ui.select({ "Open Browser", "Copy Code" }, { prompt = msg }, function(choice)
      if choice == "Open Browser" then
        vim.ui.open(result.verificationUriComplete)
      elseif choice == "Copy Code" then
        vim.fn.setreg("+", result.userCode or "")
        vim.notify("Code copied to clipboard")
        vim.ui.open(result.verificationUriComplete)
      end
    end)
  end)
end

return M
