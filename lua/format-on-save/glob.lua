local util = require("format-on-save.util")

---@param path string
---@param patterns string|string[]
---@return string
local function multiglob(path, patterns)
  if type(patterns) == "string" then
    patterns = { patterns }
  end

  for _, pattern in ipairs(patterns) do
    util.debug("multiglob", { path = path, pattern = pattern })
    local result = vim.fn.glob(path .. "/" .. pattern)
    util.debug("multiglob", { pattern = pattern, result = result })
    if #result ~= 0 then
      return result
    end
  end

  return ""
end

---@class FindGlobOptions
---@field stop_path? string

-- Searches for a glob pattern from a given path up to the root
-- (like findfile() but with globs)
--
-- Example: find(".eslintrc.*", expand("%:p:h"))
--
-- By default it stops at the root, but you can provide a custom stop path:
--
-- local root_finders = require('format-on-save.root-finders')
-- find(".eslintrc.*", expand("%:p:h"), { stop_path = root_finders.git() })
--
---@param pattern string|string[]
---@param start_path string
---@param opts? FindGlobOptions
---@return string|nil
local function find(pattern, start_path, opts)
  if opts == nil then
    opts = {}
  end

  if opts.stop_path ~= nil then
    opts.stop_path = opts.stop_path:gsub("/$", "")
  end

  util.debug("glob.find", { pattern, start_path, opts })

  local result = ""
  local path = start_path
  while #result == 0 do
    result = multiglob(path, pattern)
    if #result ~= 0 then
      return result
    end

    if path == "/" or path == opts.stop_path then
      break
    end

    path = vim.fn.fnamemodify(path, ":h")
  end

  return nil
end

return { find = find }
