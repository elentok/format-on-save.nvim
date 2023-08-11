local util = require("format-on-save.util")
local update_buffer = require("format-on-save.update-buffer")

-- Formats the current buffer with a formatter function
---@param formatter CustomFormatter
local function format_with_custom(formatter)
  util.debug("format_with_custom", { formatter = formatter })
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local formatted_lines = formatter.format(lines)
  if formatted_lines ~= nil then
    update_buffer(lines, formatted_lines)
  end
end

return format_with_custom
