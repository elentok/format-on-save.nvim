---@class ShellFormatter
---@field mode "shell"
---@field cmd string|string[]

---@class LspFormatter
---@field mode "lsp"
---@field client_name? string

---@class Config
---@field exclude_path_patterns string[] Paths where format-on-save is disabled
---@field formatter_by_ft { [string]: ShellFormatter | LspFormatter }
---@field enabled boolean

---@type Config
local config = {
  exclude_path_patterns = {},
  formatter_by_ft = {},
  enabled = true,
}

return config
