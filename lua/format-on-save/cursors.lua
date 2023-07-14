local M = {}

-- Finds all of the windows that are showing the current buffer.
---@return number[] Window handles
local function get_current_buf_windows()
  local current_buf = vim.api.nvim_get_current_buf()

  local windows = vim.api.nvim_list_wins()
  local buffer_windows = {}
  for _, win in ipairs(windows) do
    local win_buf = vim.api.nvim_win_get_buf(win)

    if win_buf == current_buf then
      table.insert(buffer_windows, win)
    end
  end

  return buffer_windows
end

---@alias BufferCursors { [number]: number[] } Window cursor by window handle

-- Returns a mapping between the window handle of each window that is
-- showing the current buffer and its current cursor location.
---@return BufferCursors Window cursor by window handle
local function get_current_buf_win_cursors()
  local cursors = {}

  local buffer_windows = get_current_buf_windows()
  for _, win in ipairs(buffer_windows) do
    cursors[win] = vim.api.nvim_win_get_cursor(win)
  end

  return cursors
end

-- A mapping between buffer handle and the last known cursor position of each
-- window showing this buffer.
---@type { [number]: BufferCursors }
local win_cursor_cache_by_buf = {}

-- Saves the current cursor position of every window showing this buffer.
function M.save_current_buf_cursors()
  local cursors = get_current_buf_win_cursors()
  win_cursor_cache_by_buf[vim.api.nvim_get_current_buf()] = cursors
end

-- Restore the cursor position of every window showing this buffer to the last
-- saved value.
function M.restore_current_buf_cursors()
  local current_buf = vim.api.nvim_get_current_buf()

  for win, cursor in pairs(win_cursor_cache_by_buf[current_buf] or {}) do
    cursor[1] = math.min(cursor[1], vim.api.nvim_buf_line_count(0))
    vim.api.nvim_win_set_cursor(win, cursor)
  end
end

return M
