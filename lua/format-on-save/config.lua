---@class ShellFormatterOptions
---@field cmd string|string[]

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
---@alias LazyFormatter fun(): NonLazyFormatter

---@alias Formatter LazyFormatter | NonLazyFormatter

---@class Config
---@field exclude_path_patterns string[] Paths where format-on-save is disabled
---@field formatter_by_ft { [string]: Formatter|Formatter[] }
---@field enabled boolean

---@type Config
local config = {
  exclude_path_patterns = {},
  formatter_by_ft = {},
  enabled = true,
}

return config
