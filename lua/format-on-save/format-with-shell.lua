local config = require("format-on-save.config")
local systemlist = require("format-on-save.systemlist")
local util = require("format-on-save.util")
local update_buffer = require("format-on-save.update-buffer")

---@param lines string[]
---@return string[]
local function clean_ascii_colors(lines)
  return vim.tbl_map(function(line)
    return vim.fn.substitute(line, "\\e\\[[0-9;]*m", "", "g")
  end, lines)
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

  local cmd = opts.cmd
  if type(cmd) == "function" then
    cmd = cmd()
  else
    cmd = vim.list_extend({}, cmd)
  end

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

---@param opts ShellFormatter
local function format_with_shell(opts)
  util.debug("format_with_shell", opts)
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
    local error_message = clean_ascii_colors(result.stdout)
    vim.list_extend(error_message, clean_ascii_colors(result.stderr))
    config.error_notifier.show({
      title = "Formatter error",
      body = error_message,
    })
    return
  end

  config.error_notifier.hide()

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

return format_with_shell
