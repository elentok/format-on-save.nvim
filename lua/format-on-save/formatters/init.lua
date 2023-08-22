local root_finders = require("format-on-save.root-finders")
local if_file_exists = require("format-on-save.formatters.if-file-exists")
local remove_trailing = require("format-on-save.formatters.remove-trailing")
local create = require("format-on-save.formatters.create")

local M = {
  shell = create.shell,
  lsp = create.lsp,
  custom = create.custom,
  remove_trailing_whitespace = remove_trailing.whitespace,
}

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

M.prettierd = create.shell({ cmd = { "prettierd", "%" } })
M.black = create.shell({ cmd = { "black", "--stdin-filename", "%", "--quiet", "-" } })
M.ruff = create.shell({ cmd = { "ruff", "check", "--stdin-filename", "%", "--fix-only", "-" } })
M.shfmt = create.shell({ cmd = { "shfmt", "-i", "2", "-bn", "-ci", "-sr" } })
M.stylua =
  create.shell({ cmd = { "stylua", "--search-parent-directories", "--stdin-filepath", "%", "-" } })
M.eslint_d_fix =
  create.shell({ cmd = { "eslint_d", "--fix-to-stdout", "--stdin", "--stdin-filename", "%" } })

-- Only runs if it can find an .eslintrc.* file
M.lazy_eslint_d_fix = if_file_exists({
  pattern = ".eslintrc.*",
  formatter = M.eslint_d_fix,
  stop_path = root_finders.git,
})

return M
