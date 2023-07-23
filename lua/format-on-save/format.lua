local config = require("format-on-save.config")
local cursors = require("format-on-save.cursors")
local systemlist = require("format-on-save.systemlist")
local util = require("format-on-save.util")

local function is_current_buf_excluded()
  local path = vim.fn.expand("%:p")
  return util.is_path_excluded(path)
end

-- When the command is an array, first expand "%" array items to the full file
-- path and then concat to a single string.
---@param opts ShellFormatter
---@param tempfile? string If defined this value is used to expand the "%" value
---@return string|nil
local function expand_and_concat_cmd(opts, tempfile)
  if type(opts.cmd) == "string" then
    vim.notify(
      "Shell formatters with a string cmd are deprecated, please use an array",
      vim.log.levels.WARN
    )
    return opts.cmd --[[@as string]]
  end

  local filename = tempfile
  if filename == nil then
    filename = vim.fn.expand("%")
  end

  local cmd = vim.list_extend({}, opts.cmd)

  if opts.expand_executable then
    local cmd_fullpath = vim.fn.exepath(cmd[1])
    if cmd_fullpath == "" then
      vim.notify(
        string.format("Formatter executable '%s' is missing", cmd[1]),
        vim.log.levels.ERROR
      )
      return nil
    end
    cmd[1] = cmd_fullpath
  end

  for index, value in ipairs(cmd) do
    if value == "%" then
      cmd[index] = vim.fn.shellescape(filename)
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

---@param opts ShellFormatter
local function prepare_tempfile(opts)
  if opts.tempfile == nil then
    return nil
  end

  if opts.tempfile == "random" then
    local tempfile = vim.fn.tempname()
    local ext = vim.fn.expand("%:e")
    if #ext ~= 0 then
      tempfile = tempfile .. "." .. ext
    end
    return tempfile
  end

  return opts.tempfile()
end

---@param original_lines string[]
---@param formatted_lines string[]
local function update_buffer(original_lines, formatted_lines)
  if not config.partial_update then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
    return
  end

  if #formatted_lines < #original_lines then
    -- delete extra lines
    vim.api.nvim_buf_set_lines(0, #formatted_lines, -1, false, {})
  end

  for index, formatted_line in pairs(formatted_lines) do
    if formatted_line ~= original_lines[index] then
      if config.debug then
        print(
          string.format(
            "[format-on-save update buffer] setting line #%d to '%s'",
            index,
            formatted_line
          )
        )
      end
      vim.fn.setline(index, formatted_line)
      -- vim.api.nvim_buf_set_lines(0, index - 1, index, false, { formatted_line })
    end
  end
end

---@param opts ShellFormatter
local function format_with_shell(opts)
  local tempfile = prepare_tempfile(opts)

  local cmd = expand_and_concat_cmd(opts, tempfile)
  if cmd == nil then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  if tempfile ~= nil then
    vim.fn.writefile(lines, tempfile)
  end

  local result = systemlist(cmd, lines)
  if result.exitcode ~= 0 then
    local message = vim.fn.join(vim.list_extend(result.stdout, result.stderr), "\n")
    vim.notify(
      "Error formatting:\n\n" .. message,
      vim.log.levels.ERROR,
      { title = "Formatter error" }
    )
    return
  end

  if #result.stderr > 0 and config.stderr_loglevel ~= vim.log.levels.OFF then
    local message = string.format(
      'Formatter "%s" was successful but included stderr:\n%s\n',
      cmd,
      vim.fn.join(result.stderr, "\n")
    )
    vim.notify(message, config.stderr_loglevel, { title = "Formatter warning" })
  end

  local formatted_lines = result.stdout
  if tempfile ~= nil then
    formatted_lines = vim.fn.readfile(tempfile)
    os.remove(tempfile)
  end

  update_buffer(lines, formatted_lines)
end

-- Formats the current buffer with a formatter function
---@param formatter CustomFormatter
local function format_with_custom(formatter)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local formatted_lines = formatter.format(lines)
  if formatted_lines ~= nil then
    update_buffer(lines, formatted_lines)
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

  -- Lazy formatter
  if type(formatter) == "function" then
    formatter = formatter()
  end

  if formatter == nil then
    return
  end

  ---@type Formatter[]
  local formatters
  if vim.tbl_islist(formatter) then
    formatters = formatter
  else
    formatters = { formatter }
  end

  for _, single_formatter in ipairs(formatters) do
    if single_formatter ~= nil then
      if single_formatter.mode == "lsp" then
        format_with_lsp(single_formatter.client_name)
      elseif single_formatter.mode == "shell" then
        format_with_shell(single_formatter --[[@as ShellFormatter]])
      elseif single_formatter.mode == "custom" then
        format_with_custom(single_formatter --[[@as CustomFormatter]])
      else
        vim.notify(
          string.format("Error: invalid formatter %s", vim.inspect(single_formatter)),
          vim.log.levels.ERROR
        )
      end
    end
  end
end

return format
