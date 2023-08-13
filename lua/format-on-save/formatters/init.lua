local root_finders = require("format-on-save.root-finders")
local if_file_exists = require("format-on-save.formatters.if-file-exists")

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
---@param opts IfFileExistsOptions|string|string[]
---@param formatter_deprecated? NonLazyFormatter|NonLazyFormatter[] depercated
---@return LazyFormatter
function M.if_file_exists(opts, formatter_deprecated)
  -- TODO: remove this after there's no need to support the deprecated version
  if type(opts) == "string" or (type(opts) == "table" and vim.tbl_islist(opts)) then
    vim.notify(
      "DEPRECATED: formatters.if_file_exists should be called with an options object, e.g. { pattern: '.eslintrc.*', formatter: formatters.eslint_d }",
      vim.log.levels.WARN
    )

    return if_file_exists({
      pattern = opts,
      formatter = formatter_deprecated,
    })
  end

  return if_file_exists(opts)
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
M.lazy_eslint_d_fix = M.if_file_exists({
  pattern = ".eslintrc.*",
  formatter = M.eslint_d_fix,
  stop_path = root_finders.git,
})

M.remove_trailing_whitespace = M.custom({
  format = function(lines)
    return vim.tbl_map(function(line)
      return line:gsub("%s*$", "")
    end, lines)
  end,
})

return M
