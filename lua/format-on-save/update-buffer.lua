local config = require("format-on-save.config")
local refine_edits = require("format-on-save.refine-edits")
local util = require("format-on-save.util")

local NEWLINE_CHAR = string.byte("\n")

---@class NormalizedHunk
---@field kind "add" | "del" | "sub"
---@field add_start integer
---@field add_count integer
---@field add_end integer
---@field del_start integer
---@field del_count integer
---@field del_end integer

---@alias VimDiffHunk { [1]: integer; [2]: integer; [3]: integer; [4]: integer }

---@param hunk VimDiffHunk
---@return NormalizedHunk
local function normalize_hunk(hunk)
  local ds, dc, as, ac = unpack(hunk)

  -- `vim.diff` returns indices of a unified diff hunks and 0 as a count in
  -- range has a bit unintuitive meaning. It means that range actually starts
  -- on the next line, so we take that into account here.
  --
  -- References:
  --   https://www.artima.com/weblogs/viewpost.jsp?thread=164293
  --   https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html
  if dc == 0 then
    ds = ds + 1
  end
  if ac == 0 then
    as = as + 1
  end

  ---@type NormalizedHunk
  local result = {
    kind = ac == 0 and "del" or dc == 0 and "add" or "sub",
    add_start = as,
    add_count = ac,
    add_end = as + ac - 1,
    del_start = ds,
    del_count = dc,
    del_end = ds + dc - 1,
  }

  return result
end

---@param lines string[]
---@return number[]
local function lines_to_chars(lines)
  ---@type number[]
  local result = {}

  for i, line in ipairs(lines) do
    for j = 1, #line do
      result[#result + 1] = string.byte(line, j)
    end

    if i ~= #lines then
      result[#result + 1] = NEWLINE_CHAR
    end
  end

  return result
end

---@class NvimBufSetTextArgs
---@field start_row integer
---@field start_col integer
---@field end_row integer
---@field end_col integer
---@field replacement string[]

---@param linewise_hunk NormalizedHunk
---@param hunks NormalizedHunk[]
---@param original_chars integer[]
---@param formatted_chars integer[]
---@return NvimBufSetTextArgs[]
local function convert_charwise_hunks_to_set_text_args(
  linewise_hunk,
  hunks,
  original_chars,
  formatted_chars
)
  ---@param chars string[]
  ---@param start_index integer
  ---@param start_row integer
  ---@param start_col integer
  ---@param end_index integer
  ---@return integer
  ---@return integer
  ---@return integer
  local function advance_char_index(chars, start_index, start_row, start_col, end_index)
    local index = start_index
    local row = start_row
    local col = start_col

    while index < end_index do
      if chars[index] == NEWLINE_CHAR then
        row = row + 1
        col = 0
      else
        col = col + 1
      end

      index = index + 1
    end

    return index, row, col
  end

  local start_row = linewise_hunk.del_start - 1
  local start_col = 0

  local original_char_index = 1
  local formatted_chars_str = table.concat(vim.tbl_map(string.char, formatted_chars), "")

  ---@type NvimBufSetTextArgs[]
  local set_text_args = {}

  for _, hunk in ipairs(hunks) do
    original_char_index, start_row, start_col =
      advance_char_index(original_chars, original_char_index, start_row, start_col, hunk.del_start)

    local end_row = start_row
    local end_col = start_col

    original_char_index, end_row, end_col =
      advance_char_index(original_chars, original_char_index, end_row, end_col, hunk.del_end + 1)

    local replacement = vim.split(
      string.sub(formatted_chars_str, hunk.add_start, hunk.add_end),
      "\n",
      { plain = true }
    )

    set_text_args[#set_text_args + 1] = {
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
      replacement = replacement,
    }

    start_row = end_row
    start_col = end_col
  end

  return set_text_args
end

---@param linewise_hunk NormalizedHunk
---@param original_lines string[]
---@param formatted_lines string[]
local function update_buffer_with_charwise_diff(linewise_hunk, original_lines, formatted_lines)
  local original_hunk_lines =
    vim.list_slice(original_lines, linewise_hunk.del_start, linewise_hunk.del_end)

  local formatted_hunk_lines =
    vim.list_slice(formatted_lines, linewise_hunk.add_start, linewise_hunk.add_end)

  local original_chars = lines_to_chars(original_hunk_lines)
  local formatted_chars = lines_to_chars(formatted_hunk_lines)

  ---@type NormalizedHunk[]
  local hunks = {}

  local charwise_hunks = vim.tbl_map(
    normalize_hunk,
    vim.diff(
      table.concat(original_chars, "\n") .. "\n",
      table.concat(formatted_chars, "\n") .. "\n",
      {
        interhunkctxlen = 1,
        result_type = "indices",
      }
    ) --[[@as number[][] ]]
  )

  for _, charwise_hunk in ipairs(charwise_hunks) do
    if
      charwise_hunk.kind == "sub"
      -- Estimate Hirschberg algorithm complexity
      and charwise_hunk.add_count * charwise_hunk.del_count < 400
    then
      local original_hunk_chars = vim.tbl_map(
        string.char,
        vim.list_slice(original_chars, charwise_hunk.del_start, charwise_hunk.del_end)
      )

      local formatted_hunk_chars = vim.tbl_map(
        string.char,
        vim.list_slice(formatted_chars, charwise_hunk.add_start, charwise_hunk.add_end)
      )

      for _, h in ipairs(refine_edits(original_hunk_chars, formatted_hunk_chars)) do
        hunks[#hunks + 1] = normalize_hunk({
          charwise_hunk.del_start + h[1] - 1,
          h[2],
          charwise_hunk.add_start + h[3] - 1,
          h[4],
        })
      end
    else
      hunks[#hunks + 1] = charwise_hunk
    end
  end

  local set_text_args =
    convert_charwise_hunks_to_set_text_args(linewise_hunk, hunks, original_chars, formatted_chars)

  local current_buf = vim.api.nvim_get_current_buf()

  ---@class CursorPosition
  ---@field win number
  ---@field line integer
  ---@field column integer

  ---@type CursorPosition[]
  local cursors = {}

  local should_fix_cursor = not vim.fn.has("nvim-0.10")

  if should_fix_cursor then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == current_buf then
        local line, column = unpack(vim.api.nvim_win_get_cursor(win))

        if line >= linewise_hunk.del_start and line <= linewise_hunk.del_end then
          cursors[#cursors + 1] = {
            win = win,
            line = line,
            column = column,
          }
        end
      end
    end
  end

  for _, args in ipairs(util.list_reverse(set_text_args)) do
    vim.api.nvim_buf_set_text(
      0,
      args.start_row,
      args.start_col,
      args.end_row,
      args.end_col,
      args.replacement
    )

    local start_row = args.start_row + 1
    local start_col = args.start_col
    local end_row = args.end_row + 1
    local end_col = args.end_col

    local replacement = #args.replacement == 0 and { "" } or args.replacement

    local new_row_count = #replacement
    local old_row_count = (end_row - start_row + 1)

    if should_fix_cursor then
      for _, cursor in ipairs(cursors) do
        if cursor.line >= start_row and cursor.line <= end_row then
          local cursor_gravity_col = cursor.column + 1

          if cursor.line == end_row and cursor_gravity_col > end_col then
            cursor.line = cursor.line + new_row_count - old_row_count
            cursor.column = cursor.column + #replacement[new_row_count] - end_col

            if new_row_count == 1 then
              cursor.column = cursor.column + start_col
            end
          else
            local repl_end_row = start_row + #replacement - 1
            local cursor_was_after_end_row = cursor.line > repl_end_row

            if cursor_was_after_end_row then
              cursor.line = repl_end_row
            end

            local repl_start_col = new_row_count == 1 and start_col or 0
            local index = cursor.line - start_row + 1
            local repl_item = replacement[index]
            local repl_end_col = repl_start_col + #repl_item

            if
              cursor_was_after_end_row
              or (cursor.line == repl_end_row and cursor.column > repl_end_col)
            then
              cursor.column = repl_end_col

              if cursor.column - 1 >= repl_start_col then
                cursor.column = cursor.column - 1
              end
            end
          end

          local last_valid_col = #(vim.fn.getline(cursor.line)) - 1

          if last_valid_col < 0 then
            last_valid_col = 0
          end

          if cursor.column > last_valid_col then
            cursor.column = last_valid_col
          elseif cursor.column < 0 then
            cursor.column = 0
          end
        elseif cursor.line > end_row then
          cursor.line = cursor.line + new_row_count - old_row_count
        end
      end
    end
  end

  if should_fix_cursor then
    for _, cursor in ipairs(cursors) do
      vim.api.nvim_win_set_cursor(cursor.win, { cursor.line, cursor.column })
    end
  end
end

---@param original_lines string[]
---@param formatted_lines string[]
local function update_buffer_with_diff(original_lines, formatted_lines)
  local linewise_hunks = vim.tbl_map(
    normalize_hunk,
    vim.diff(
      table.concat(original_lines, "\n") .. "\n",
      table.concat(formatted_lines, "\n") .. "\n",
      {
        interhunkctxlen = 5,
        result_type = "indices",
      }
    ) --[[@as number[][] ]]
  )

  for _, linewise_hunk in ipairs(util.list_reverse(linewise_hunks)) do
    if config.experiments.adjust_cursor_position and linewise_hunk.kind == "sub" then
      update_buffer_with_charwise_diff(linewise_hunk, original_lines, formatted_lines)
    else
      vim.api.nvim_buf_set_lines(
        0,
        linewise_hunk.del_start - 1,
        linewise_hunk.del_end,
        true,
        vim.list_slice(formatted_lines, linewise_hunk.add_start, linewise_hunk.add_end)
      )
    end
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
