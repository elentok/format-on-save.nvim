local config = require("format-on-save.config")
local util = require("format-on-save.util")

---@param original_lines string[]
---@param formatted_lines string[]
local function update_buffer(original_lines, formatted_lines)
  if not config.partial_update then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
    return
  end

  if #formatted_lines < #original_lines then
    -- delete extra lines
    vim.api.nvim_buf_set_lines(0, #formatted_lines, -1, false, {})
  end

  for index, formatted_line in pairs(formatted_lines) do
    if formatted_line ~= original_lines[index] then
      util.debug(string.format("[update buffer] setting line #%d to '%s'", index, formatted_line))
      vim.fn.setline(index, formatted_line)
      -- vim.api.nvim_buf_set_lines(0, index - 1, index, false, { formatted_line })
    end
  end
end

return update_buffer
