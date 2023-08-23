local config = require("format-on-save.config")
local format = require("format-on-save.format")
local cursors = require("format-on-save.cursors")

---@class ExperimentOptions
---@field partial_update? false | 'line-by-line' | 'diff'
---@field disable_restore_cursors? boolean

---@class SetupOptions
---@field exclude_path_patterns? string[] Paths where format-on-save is disabled
---@field formatter_by_ft? { [string]: Formatter|Formatter[] }
---@field fallback_formatter? Formatter|Formatter[] Formatter to use if no formatter was found for the current filetype
---@field auto_commands? boolean Add BufWritePre and BufWritePost auto commands (defaults to true)
---@field user_commands? boolean Add Format, FormatOn and FormatOff auto commands (defaults to true)
---@field debug? boolean Enable extra logs for debugging (defaults to false)
---@field stderr_loglevel? integer The log level when a formatter was successful but included stderr output (from |vim.log.levels|, defaults to WARN)
---@field partial_update? boolean|'diff' DEPRECATED (see "experiments.partial_update")
---@field run_with_sh? boolean Prefix all shell commands with "sh -c" (default: true)
---@field error_notifier? ErrorNotifier How to display error messages (default: vim.notify() via require('format-on-save.notifiers.vim'))
---@field experiments? ExperimentOptions Experiment flags

---@param opts SetupOptions
local function merge_config(opts)
  vim.list_extend(config.exclude_path_patterns, opts.exclude_path_patterns or {})
  config.formatter_by_ft =
    vim.tbl_extend("force", config.formatter_by_ft, opts.formatter_by_ft or {})

  if opts.run_with_sh ~= nil then
    config.run_with_sh = opts.run_with_sh
  end

  if opts.error_notifier ~= nil then
    config.error_notifier = opts.error_notifier
  end

  if opts.fallback_formatter ~= nil then
    config.fallback_formatter = opts.fallback_formatter
  end

  if opts.stderr_loglevel ~= nil then
    config.stderr_loglevel = opts.stderr_loglevel
  end

  if opts.partial_update ~= nil then
    vim.notify(
      "Format-on-save: the 'partial_update' config variable is deprecated, please use 'experiments.partial_update'.",
      vim.log.levels.WARN
    )

    if opts.experiments == nil then
      opts.experiments = {}
    end

    if opts.experiments.partial_update == nil then
      if opts.partial_update == "diff" then
        opts.experiments.partial_update = "diff"
      elseif opts.partial_update == true then
        opts.experiments.partial_update = "line-by-line"
      end
    end
  end

  if opts.experiments ~= nil then
    vim.tbl_extend("force", config.experiments, opts.experiments)
  end

  if opts.debug ~= nil then
    config.debug = opts.debug
  end
end

local function register_auto_commands()
  local augroup_id = vim.api.nvim_create_augroup("FormatOnSave", {})
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = "*",
    callback = function()
      format()
    end,
    group = augroup_id,
  })

  if config.experiments.disable_restore_cursors ~= true then
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      pattern = "*",
      callback = cursors.restore_current_buf_cursors,
      group = augroup_id,
    })
  end
end

local function enable()
  config.enabled = true
end

local function disable()
  config.enabled = false
end

local function register_user_commands()
  vim.api.nvim_create_user_command("Format", function()
    format()
  end, {})
  vim.api.nvim_create_user_command("FormatOn", enable, {})
  vim.api.nvim_create_user_command("FormatOff", disable, {})
  vim.api.nvim_create_user_command("FormatDebugOn", function()
    config.debug = true
  end, {})
  vim.api.nvim_create_user_command("FormatDebugOff", function()
    config.debug = false
  end, {})
end

---@param opts SetupOptions
local function setup(opts)
  merge_config(opts)

  -- Register auto commands
  if opts.auto_commands ~= false then
    register_auto_commands()
  end

  -- Register user commands
  if opts.user_commands ~= false then
    register_user_commands()
  end
end

return {
  format = format,
  restore_cursors = cursors.restore_current_buf_cursors,
  setup = setup,
  enable = enable,
  disable = disable,
}
