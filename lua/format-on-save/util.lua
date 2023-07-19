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

return M
