local glob = require("format-on-save.glob")
local root_finders = require("format-on-save.root-finders")

---@class IfFileExistsOptions
---@field pattern string|string[]
---@field formatter NonLazyFormatter|NonLazyFormatter[]
---@field stop_path? fun():string Specify where to stop searching (to avoid going all the way to the top, defaults to the git root)

-- Creates a Lazy formatter that returns a set of non-lazy formatters if
-- one of the given files (globs are supported) exists in the one of the parent
-- directories.
---@param opts IfFileExistsOptions
---@return LazyFormatter
local function if_file_exists(opts)
  opts = vim.tbl_extend("force", { stop_path = root_finders.git }, opts)

  return function()
    local stop_path = nil
    if opts.stop_path ~= nil then
      stop_path = opts.stop_path()
    end
    if glob.find(opts.pattern, vim.fn.expand("%:p:h"), { stop_path = stop_path }) then
      return opts.formatter
    end

    return nil
  end
end

return if_file_exists
