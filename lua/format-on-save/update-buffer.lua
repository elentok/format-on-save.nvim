local config = require("format-on-save.config")
local util = require("format-on-save.util")

---@param original_lines string[]
---@param formatted_lines string[]
local function update_buffer_with_diff(original_lines, formatted_lines)
  local original = table.concat(original_lines, "\n") .. "\n"
  local formatted = table.concat(formatted_lines, "\n") .. "\n"

  local hunks = vim.diff(original, formatted, {
    result_type = "indices",
  }) --[[@as number[][] ]]

  for hunk_index = vim.tbl_count(hunks), 1, -1 do
    local hunk = hunks[hunk_index]
    local original_start, original_count, formatted_start, formatted_count = unpack(hunk)

    -- `vim.diff` returns indices of a unified diff hunks and 0 there is
    -- considered special in that it means that hunk actuall starts on the next
    -- line, so we take that into account here.
    --
    -- References:
    --   https://www.artima.com/weblogs/viewpost.jsp?thread=164293
    --   https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html
    if original_count == 0 then
      original_start = original_start + 1
    end

    local formatted_hunk_lines = {}
    for line = formatted_start, formatted_start + formatted_count - 1 do
      table.insert(formatted_hunk_lines, formatted_lines[line])
    end

    local start_index = original_start - 1
    local end_index = start_index + original_count
    vim.api.nvim_buf_set_lines(0, start_index, end_index, true, formatted_hunk_lines)
  end
end

---@param original_lines string[]
---@param formatted_lines string[]
local function update_buffer_line_by_line(original_lines, formatted_lines)
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

---@param original_lines string[]
---@param formatted_lines string[]
local function update_buffer(original_lines, formatted_lines)
  if config.experiments.partial_update == "diff" then
    update_buffer_with_diff(original_lines, formatted_lines)
  elseif config.experiments.partial_update == "line-by-line" then
    update_buffer_line_by_line(original_lines, formatted_lines)
  else
    vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
  end
end

return update_buffer
