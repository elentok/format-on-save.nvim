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
---@field auto_commands? boolean Add BufWritePre and BufWritePost auto commands (defaults to true)
---@field user_commands? boolean Add Format, FormatOn and FormatOff auto commands (defaults to true)

---@param opts SetupOptions
function M.setup(opts)
  vim.list_extend(config.exclude_path_patterns, opts.exclude_path_patterns or {})
  config.formatter_by_ft = vim.tbl_extend("force", config.formatter_by_ft, opts.formatter_by_ft or {})

  -- Register auto commands
  if opts.auto_commands ~= false then
    local augroup_id = vim.api.nvim_create_augroup("FormatOnSave", {})
    vim.api.nvim_create_autocmd(
      { "BufWritePre" },
      { pattern = "*", callback = format, group = augroup_id }
    )
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
