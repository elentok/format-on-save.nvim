local config = require("format-on-save.config")

---@class CommandResult
---@field stdout string[] The lines sent to stdout
---@field stderr string[] The lines sent to stderr
---@field exitcode number The process exit code (vim.v.shell_error)

-- Executes a command using `vim.fn.system` but splits stderr and stdout
---@param cmd string|string[]
---@param input? string[]
---@return CommandResult
local function systemlist(cmd, input)
  if type(cmd) == "table" and vim.islist(cmd) then
    cmd = table.concat(cmd, " ")
  end
  local stderr_tempfile = vim.fn.tempname()
  cmd = string.format("(%s) 2> %s", cmd, vim.fn.shellescape(stderr_tempfile))

  if config.run_with_sh then
    cmd = { "sh", "-c", cmd }
  end

  local stdout = vim.fn.systemlist(cmd, input)

  local stderr = {}
  if vim.fn.filereadable(stderr_tempfile) then
    stderr = vim.fn.readfile(stderr_tempfile)
    os.remove(stderr_tempfile)
  end

  return {
    stdout = stdout,
    stderr = stderr,
    exitcode = vim.v.shell_error,
  }
end

return systemlist
