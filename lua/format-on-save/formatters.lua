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

-- Creates a Lazy formatter that returns a set of non-lazy formatters if
-- one of the given files (globs are supported) exists in the one of the parent
-- directories.
---@param glob_pattern string|string[]
---@param formatter NonLazyFormatter|NonLazyFormatter[]
---@return LazyFormatter
function M.if_file_exists(glob_pattern, formatter)
  return function()
    if type(glob_pattern) == "string" then
      glob_pattern = { glob_pattern }
    end

    if util.findglob(glob_pattern, vim.fn.expand("%:p:h")) then
      return formatter
    end

    return nil
  end
end

M.prettierd = M.shell({ cmd = { "prettierd", "%" } })
M.black = M.shell({ cmd = { "black", "--stdin-filename", "%", "--quiet", "-" } })
M.ruff = M.shell({ cmd = { "ruff", "check", "--stdin-filename", "%", "--fix-only", "-" } })
M.shfmt = M.shell({ cmd = { "shfmt", "-i", "2", "-bn", "-ci", "-sr" } })
M.stylua =
  M.shell({ cmd = { "stylua", "--search-parent-directories", "--stdin-filepath", "%", "-" } })
M.eslint_d_fix =
  M.shell({ cmd = { "eslint_d", "--fix-to-stdout", "--stdin", "--stdin-filename", "%" } })

-- Only runs if it can find an .eslintrc.* file
M.lazy_eslint_d_fix = M.if_file_exists(".eslintrc.*", M.eslint_d_fix)

M.remove_trailing_whitespace = M.custom({
  format = function(lines)
    return vim.tbl_map(function(line)
      return line:gsub("%s*$", "")
    end, lines)
  end,
})

return M
