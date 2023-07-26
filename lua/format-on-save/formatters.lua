local util = require("format-on-save.util")

local M = {}

-- Creates a Shell formatter.
---@param opts ShellFormatterOptions
---@return ShellFormatter|nil
function M.shell(opts)
  return vim.tbl_extend("force", { mode = "shell", expand_executable = true }, opts or {})
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
M.stylua =
  M.shell({ cmd = { "stylua", "--search-parent-directories", "--stdin-filepath", "%", "-" } })
M.eslint_d_fix =
  M.shell({ cmd = { "eslint_d", "--fix-to-stdout", "--stdin", "--stdin-filename", "%" } })

-- Only runs if it can find an .eslintrc.* file
M.lazy_eslint_d_fix = function()
  local eslintrc = util.findglob(".eslintrc.*", vim.fn.expand("%:p:h"))
  util.debug("eslint_d_fix", { eslintrc = eslintrc })
  if eslintrc ~= nil then
    return M.eslint_d_fix
  end
end

M.remove_trailing_whitespace = M.custom({
  format = function(lines)
    return vim.tbl_map(function(line)
      return line:gsub("%s*$", "")
    end, lines)
  end,
})

return M
