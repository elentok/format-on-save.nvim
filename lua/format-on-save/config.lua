---@class ShellFormatterOptions
---@field cmd string|string[]

---@class ShellFormatter: ShellFormatterOptions
---@field mode "shell"
--
---@class LspFormatterOptions
---@field client_name? string

---@class LspFormatter: LspFormatterOptions
---@field mode "lsp"

---@alias NonLazyFormatter LspFormatter | ShellFormatter
---@alias LazyFormatter fun(): NonLazyFormatter

---@alias Formatter LazyFormatter | NonLazyFormatter

---@class Config
---@field exclude_path_patterns string[] Paths where format-on-save is disabled
---@field formatter_by_ft { [string]: Formatter }
---@field enabled boolean

---@type Config
local config = {
  exclude_path_patterns = {},
  formatter_by_ft = {},
  enabled = true,
}

return config
