---@class CommandResult
---@field stdout string[] The lines sent to stdout
---@field stderr string[] The lines sent to stderr
---@field exitcode number The process exit code (vim.v.shell_error)

-- Executes a command using `vim.fn.system` but splits stderr and stdout
---@param cmd string|string[]
---@param input? string[]
---@return CommandResult
local function systemlist(cmd, input)
  local stderr_tempfile = vim.fn.tempname()
  cmd = string.format('%s 2> %s', cmd, vim.fn.shellescape(stderr_tempfile))
  local stdout = vim.fn.systemlist(cmd, input)

  local stderr = {}
  if vim.fn.filereadable(stderr_tempfile) then
    stderr = vim.fn.readfile(stderr_tempfile)
    os.remove(stderr_tempfile)
  end

  return {
    stdout = stdout,
    stderr = stderr,
    exitcode = vim.v.shell_error
  }
end

return systemlist
