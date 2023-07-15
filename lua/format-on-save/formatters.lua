local M = {}

-- Creates a Shell formatter.
---@param opts ShellFormatterOptions
---@return ShellFormatter
function M.shell(opts)
  return vim.tbl_extend("force", { mode = "shell" }, opts or {})
end

-- Creates an LSP formatter.
-- Pass the 'client_name' option to use a specific client.
---@param opts LspFormatterOptions
---@return LspFormatter
function M.lsp(opts)
  return vim.tbl_extend("force", { mode = "lsp" }, opts or {})
end

-- Creates a Custom formatter.
---@param opts CustomFormatterOptions
---@return CustomFormatter
function M.custom(opts)
  return vim.tbl_extend("force", { mode = "custom" }, opts or {})
end

M.prettierd = M.shell({ cmd = { "prettierd", "%" } })
M.black = M.shell({ cmd = { "black", "--stdin-filename", "%", "--quiet", "-" } })
M.shfmt = M.shell({ cmd = { "shfmt", "-i", "2", "-bn", "-ci", "-sr" } })

M.remove_trailing_whitespace = M.custom({
  format = function(lines)
    return vim.tbl_map(function(line)
      return line:gsub("%s*$", "")
    end, lines)
  end
})

return M
