local M = {}

M.prettierd = { mode = "shell", cmd = { "prettierd", "%" } }
M.black = { mode = "shell", cmd = { "black", "--stdin-filename", "%", "--quiet", "-" } }
M.shfmt = { mode = "shell", cmd = { "shfmt", "-i", "2", "-bn", "-ci", "-sr" } }

---@type LspFormatter
M.lsp = { mode = "lsp" }

-- Creates an LSP formatter that uses a specific LSP client_name
-- (helpful when you have multiple LSP clients for a filetype that support
-- formatting).
---@param client_name string
---@return LspFormatter
function M.specific_lsp(client_name)
  return { mode = "lsp", client_name = client_name }
end

return M
