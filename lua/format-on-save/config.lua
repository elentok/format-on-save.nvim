---@class ShellFormatterOptions
---@field cmd string|string[]
---@field tempfile? "random"|fun(): string Instead of passing the buffer through stdin write to a temp file and the shell command will modify it

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

---@alias NonLazyFormatter LspFormatter | ShellFormatter | CustomFormatter
---@alias LazyFormatter fun(): NonLazyFormatter|NonLazyFormatter[]

---@alias Formatter LazyFormatter | NonLazyFormatter

---@class Config
---@field exclude_path_patterns string[] Paths where format-on-save is disabled
---@field formatter_by_ft { [string]: Formatter|Formatter[] }
---@field enabled boolean
---@field stderr_loglevel integer The log level when a formatter was successful but included stderr output (from |vim.log.levels|, defaults to WARN)

---@type Config
local config = {
  exclude_path_patterns = {},
  formatter_by_ft = {},
  enabled = true,
  stderr_loglevel = vim.log.levels.WARN,
}

return config
