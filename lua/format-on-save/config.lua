local message_buffer = require("format-on-save.error-notifiers.message-buffer")

---@class ShellFormatterOptions
---@field cmd string[]|fun():string[]
---@field tempfile? "random"|fun(): string Instead of passing the buffer through stdin write to a temp file and the shell command will modify it
---@field expand_executable? boolean Use `vim.fn.exepath` to expand the first item in the `cmd` array (helps detect mason binaries, defaults to true)

---@class ShellFormatter: ShellFormatterOptions
---@field mode "shell"
--
---@class LspFormatterOptions
---@field client_name? string

---@class LspFormatter: LspFormatterOptions
---@field mode "lsp"

---@class CustomFormatterOptions
---@field format fun(lines: string[]): nil|string[] When the formatting fails returns nil

---@class CustomFormatter: CustomFormatterOptions
---@field mode "custom"

---@alias NonLazyFormatter nil | LspFormatter | ShellFormatter | CustomFormatter
---@alias LazyFormatter fun(): NonLazyFormatter|NonLazyFormatter[]

---@alias Formatter LazyFormatter | NonLazyFormatter

---@class Experiments
---@field partial_update false | 'line-by-line' | 'diff'
---@field disable_restore_cursors boolean
---@field adjust_cursor_position boolean

---@class Config
---@field exclude_path_patterns string[] Paths where format-on-save is disabled
---@field formatter_by_ft { [string]: Formatter|Formatter[] }
---@field fallback_formatter? Formatter|Formatter[] Formatter to use if no formatter was found for the current filetype
---@field enabled boolean
---@field debug boolean Enable extra logs for debugging (defaults to false, can also be set by setting FORMAT_ON_SAVE_DEBUG=true)
---@field stderr_loglevel integer The log level when a formatter was successful but included stderr output (from |vim.log.levels|, defaults to WARN)
---@field run_with_sh boolean Prefix all shell commands with "sh -c" (default: true)
---@field error_notifier ErrorNotifier How to display error messages (default: vim.notify() via require('format-on-save.notifiers.vim'))
---@field experiments Experiments Experiment flags

---@type Config
local config = {
  exclude_path_patterns = {},
  formatter_by_ft = {},
  enabled = true,
  debug = (vim.env.FORMAT_ON_SAVE_DEBUG == "true"),
  stderr_loglevel = vim.log.levels.WARN,
  run_with_sh = true,
  error_notifier = message_buffer,
  fallback_formatter = nil,
  experiments = {
    partial_update = false,
    disable_restore_cursors = false,
  },
}

return config
