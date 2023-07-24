local config = require("format-on-save.config")
local format = require("format-on-save.format")
local cursors = require("format-on-save.cursors")

local M = {
  format = format,
  restore_cursors = cursors.restore_current_buf_cursors,
}

---@class SetupOptions
---@field exclude_path_patterns? string[] Paths where format-on-save is disabled
---@field formatter_by_ft? { [string]: Formatter|Formatter[] }
---@field fallback_formatter? Formatter|Formatter[] Formatter to use if no formatter was found for the current filetype
---@field auto_commands? boolean Add BufWritePre and BufWritePost auto commands (defaults to true)
---@field user_commands? boolean Add Format, FormatOn and FormatOff auto commands (defaults to true)
---@field debug? boolean Enable extra logs for debugging (defaults to false)
---@field stderr_loglevel? integer The log level when a formatter was successful but included stderr output (from |vim.log.levels|, defaults to WARN)
---@field partial_update? boolean Experimental feature of only updating modified lines
---@field run_with_sh? boolean Prefix all shell commands with "sh -c" (default: true)

---@param opts SetupOptions
function M.setup(opts)
  vim.list_extend(config.exclude_path_patterns, opts.exclude_path_patterns or {})
  config.formatter_by_ft =
    vim.tbl_extend("force", config.formatter_by_ft, opts.formatter_by_ft or {})

  if opts.run_with_sh ~= nil then
    config.run_with_sh = opts.run_with_sh
  end

  if opts.fallback_formatter ~= nil then
    config.fallback_formatter = opts.fallback_formatter
  end

  if opts.stderr_loglevel ~= nil then
    config.stderr_loglevel = opts.stderr_loglevel
  end

  if opts.partial_update ~= nil then
    config.partial_update = opts.partial_update
  end

  if opts.debug ~= nil then
    config.debug = opts.debug
  end

  -- Register auto commands
  if opts.auto_commands ~= false then
    local augroup_id = vim.api.nvim_create_augroup("FormatOnSave", {})
    vim.api.nvim_create_autocmd({ "BufWritePre" }, {
      pattern = "*",
      callback = function()
        format()
      end,
      group = augroup_id,
    })
    vim.api.nvim_create_autocmd(
      { "BufWritePost" },
      { pattern = "*", callback = cursors.restore_current_buf_cursors, group = augroup_id }
    )
  end

  -- Register user commands
  if opts.auto_commands ~= false then
    vim.api.nvim_create_user_command("Format", format, {})
    vim.api.nvim_create_user_command("FormatOn", M.enable, {})
    vim.api.nvim_create_user_command("FormatOff", M.disable, {})
  end
end

function M.enable()
  config.enabled = true
end

function M.disable()
  config.enabled = false
end

return M
