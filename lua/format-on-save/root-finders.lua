-- Returns the git root of the current file
---@return string|nil
local function git_root()
  local gitdir = vim.fn.finddir(".git", ";" .. vim.fn.expand("%:p"))
  if gitdir == nil then
    return nil
  end

  return vim.fn.fnamemodify(vim.fn.fnamemodify(gitdir, ":h"), ":p")
end

return { git = git_root }
