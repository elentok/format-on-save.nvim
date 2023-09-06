local config = require("format-on-save.config")

local M = {}

---@generic T
---@param list T[]
---@return T[]
function M.list_reverse(list)
  local result = {}
  for i = #list, 1, -1 do
    result[#result + 1] = list[i]
  end
  return result
end

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
