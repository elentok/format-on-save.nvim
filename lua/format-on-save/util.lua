local config = require("format-on-save.config")

local M = {}

---@param filepath string
---@return boolean
function M.is_path_excluded(filepath)
  for _, pattern in ipairs(config.exclude_path_patterns) do
    if vim.fn.match(filepath, pattern) ~= -1 then
      print("Skipping format-on-save because file matches exclude pattern")
      return true
    end
  end

  return false
end

---@param path string
---@param patterns string|string[]
---@return string
local function multiglob(path, patterns)
  if type(patterns) == "string" then
    patterns = { patterns }
  end

  for _, pattern in ipairs(patterns) do
    M.debug("multiglob", { path = path, pattern = pattern })
    local result = vim.fn.glob(path .. "/" .. pattern)
    M.debug("multiglob", { pattern = pattern, result = result })
    if #result ~= 0 then
      return result
    end
  end

  return ""
end

-- Searches for a glob pattern from a given path up to the root
-- (like findfile() but with globs)
--
-- Example: findglob(".eslintrc.*", expand("%:p:h"))
--
---@param pattern string|string[]
---@param start_path string
---@return string|nil
function M.findglob(pattern, start_path)
  local result = ""
  local path = start_path
  while #result == 0 and path ~= "/" do
    result = multiglob(path, pattern)
    if #result ~= 0 then
      return result
    end

    path = vim.fn.fnamemodify(path, ":h")
  end

  return nil
end

--- Prints debug output
-- Based on https://github.com/nanotee/nvim-lua-guide
function M.debug(...)
  if not config.debug then
    return
  end

  local objects = { "[format-on-save]" }
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, " "))
  return ...
end

return M
