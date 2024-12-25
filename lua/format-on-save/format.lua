local config = require("format-on-save.config")
local cursors = require("format-on-save.cursors")
local util = require("format-on-save.util")
local format_with_custom = require("format-on-save.format-with-custom")
local format_with_lsp = require("format-on-save.format-with-lsp")
local format_with_shell = require("format-on-save.format-with-shell")

-- Runs formatters recursively
---@param formatter? Formatter|Formatter[]
local function run_formatters(formatter)
  if formatter == nil then
    return
  end

  -- Lazy formatter
  if type(formatter) == "function" then
    run_formatters(formatter())
    return
  end

  -- Multiple formatters
  if vim.islist(formatter) then
    for _, single_formatter in ipairs(formatter) do
      run_formatters(single_formatter)
    end
    return
  end

  if formatter.mode == "lsp" then
    format_with_lsp(formatter.client_name)
  elseif formatter.mode == "shell" then
    format_with_shell(formatter --[[@as ShellFormatter]])
  elseif formatter.mode == "custom" then
    format_with_custom(formatter --[[@as CustomFormatter]])
  else
    vim.notify(
      string.format("Error: invalid formatter %s", vim.inspect(formatter)),
      vim.log.levels.ERROR
    )
  end
end

-- Formats the current buffer synchronously.
---@param formatter? Formatter
local function format(formatter)
  if not config.enabled then
    vim.notify("Format-on-save is disabled, use :FormatOn to enable", vim.log.levels.WARN)
    return
  end

  if util.is_path_excluded(vim.fn.expand("%:p")) then
    return
  end

  cursors.save_current_buf_cursors()
  local filetype = vim.api.nvim_buf_get_option(0, "filetype")
  if formatter == nil then
    formatter = config.formatter_by_ft[filetype]
  end

  if formatter == nil then
    if config.fallback_formatter == nil then
      return
    end
    formatter = config.fallback_formatter
  end

  run_formatters(formatter)

  -- Lazy formatter
  -- if type(formatter) == "function" then
  --   formatter = formatter()
  -- end

  -- if formatter == nil then
  --   return
  -- end

  -- ---@type Formatter[]
  -- local formatters
  -- if vim.islist(formatter) then
  --   formatters = formatter
  -- else
  --   formatters = { formatter }
  -- end

  -- for _, single_formatter in ipairs(formatters) do
  --   if single_formatter ~= nil then
  --     if single_formatter.mode == "lsp" then
  --       format_with_lsp(single_formatter.client_name)
  --     elseif single_formatter.mode == "shell" then
  --       format_with_shell(single_formatter --[[@as ShellFormatter]])
  --     elseif single_formatter.mode == "custom" then
  --       format_with_custom(single_formatter --[[@as CustomFormatter]])
  --     else
  --       vim.notify(
  --         string.format("Error: invalid formatter %s", vim.inspect(single_formatter)),
  --         vim.log.levels.ERROR
  --       )
  --     end
  --   end
  -- end
end

return format
