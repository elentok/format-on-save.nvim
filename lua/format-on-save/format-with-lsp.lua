local util = require("format-on-save.util")

---@param client_name? string Use a specific LSP client
local function format_with_lsp(client_name)
  util.debug("format_with_lsp", { client_name = client_name })
  local filter = nil
  if client_name ~= nil then
    filter = function(client)
      return client.name == client_name
    end
  end

  vim.lsp.buf.format({ timeout_ms = 4000, filter = filter })
end

return format_with_lsp
