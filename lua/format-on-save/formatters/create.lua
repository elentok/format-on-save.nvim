-- Creates a Shell formatter.
---@param opts ShellFormatterOptions
---@return ShellFormatter|nil
local function shell(opts)
  return vim.tbl_extend("force", { mode = "shell", expand_executable = true }, opts or {})
end

-- Creates an LSP formatter.
-- Pass the 'client_name' option to use a specific client.
---@param opts LspFormatterOptions
---@return LspFormatter
local function lsp(opts)
  return vim.tbl_extend("force", { mode = "lsp" }, opts or {})
end

-- Creates a Custom formatter.
---@param opts CustomFormatterOptions
---@return CustomFormatter
local function custom(opts)
  return vim.tbl_extend("force", { mode = "custom" }, opts or {})
end

return { shell = shell, lsp = lsp, custom = custom }
