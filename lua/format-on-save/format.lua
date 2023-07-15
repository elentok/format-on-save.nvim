local config = require("format-on-save.config")
local cursors = require("format-on-save.cursors")

local function is_current_buf_excluded()
  local path = vim.fn.expand("%:p")
  for _, pattern in ipairs(config.exclude_path_patterns) do
    if vim.fn.match(path, pattern) ~= -1 then
      print("Skipping format-on-save because file matches exclude pattern")
      return true
    end
  end

  return false
end


-- When the command is an array, first expand "%" array items to the full file
-- path and then concat to a single string.
---@param cmd string|string[]
---@return string
local function expand_and_concat_cmd(cmd)
  if type(cmd) == "string" then
    return cmd
  end

  for index, value in ipairs(cmd) do
    if value == "%" then
      cmd[index] = vim.fn.expand(value)
    end
  end

  return table.concat(cmd, " ")
end

---@param client_name? string Use a specific LSP client
local function format_with_lsp(client_name)
  local filter = nil
  if client_name ~= nil then
    filter = function(client)
      return client.name == client_name
    end
  end

  vim.lsp.buf.format({ timeout_ms = 4000, filter = filter })
end

---@param cmd string|string[]
local function format_with_cmd(cmd)
  cmd = expand_and_concat_cmd(cmd) .. " 2>&1"
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local output = vim.fn.system(cmd, lines)
  if vim.v.shell_error ~= 0 then
    vim.notify('Error formatting:\n\n' .. output, vim.log.levels.ERROR, { title = "Formatter error" })
    return
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn.split(output, "\n"))
end

-- Formats the current buffer with a formatter function
---@param formatter CustomFormatter
local function format_with_custom(formatter)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local output = formatter.format(lines)
  if output ~= nil then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
  end
end

-- Formats the current buffer synchronously.
local function format()
  if not config.enabled then
    vim.notify("Format-on-save is disabled, use :FormatOn to enable", vim.log.levels.WARN)
    return
  end

  cursors.save_current_buf_cursors()
  local filetype = vim.api.nvim_buf_get_option(0, "filetype")
  local formatter = config.formatter_by_ft[filetype]
  if formatter == nil or is_current_buf_excluded() then
    return
  end

  -- Lazy formatter
  if type(formatter) == "function" then
    formatter = formatter()
  end

  if formatter.mode == "lsp" then
    format_with_lsp(formatter.client_name)
  elseif formatter.mode == "shell" then
    format_with_cmd(formatter.cmd)
  elseif formatter.mode == "custom" then
    format_with_custom(formatter --[[@as CustomFormatter]])
  else
    vim.notify(string.format("Error: invalid formatter %s", vim.inspect(formatter)), vim.log.levels.ERROR)
  end
end

return format
