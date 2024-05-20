-- Find the window number associated with a specific buffer handle in a
-- specific tab
---@return number|nil
local function tabpage_get_buf_win_number(tabnr, bufnr)
  for _, winhandle in ipairs(vim.api.nvim_tabpage_list_wins(tabnr)) do
    if bufnr == vim.api.nvim_win_get_buf(winhandle) then
      return vim.api.nvim_win_get_number(winhandle)
    end
  end

  return nil
end

local function create_message_buffer()
  -- create a new message buffer
  vim.cmd([[
      belowright new
      noswapfile hide enew
      resize 10
    ]])
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "hide"
  vim.t.message_bufnr = vim.fn.bufnr()

  vim.api.nvim_buf_set_keymap(0, "n", "q", ":close<cr>", { noremap = true, silent = true })
end

local function jump_to_message_buffer_window()
  local winnr = tabpage_get_buf_win_number(0, vim.t.message_bufnr)
  if winnr then
    -- jump to the existing message window
    vim.cmd(winnr .. "wincmd w")
  else
    -- split and load the existing message buffer
    vim.cmd("belowright split")
    vim.cmd("buffer " .. vim.t.message_bufnr)
  end
end

local message_buffer = {
  -- Shows a message in buffer (when called multiple times updates the buffer)
  ---@param opts ShowOptions
  show = function(opts)
    if vim.t.message_bufnr then
      jump_to_message_buffer_window()
    else
      create_message_buffer()
    end

    vim.cmd("file " .. opts.title)
    vim.wo.wrap = true
    vim.wo.winhighlight = "Normal:Error"
    vim.wo.cursorline = false

    local lines = opts.body
    if type(lines) == "string" then
      lines = vim.fn.split(lines, "\n")
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd([[wincmd p]])
  end,

  hide = function()
    if vim.t.message_bufnr then
      if vim.api.nvim_buf_is_valid(vim.t.message_bufnr) then
        vim.cmd("silent bd " .. vim.t.message_bufnr)
      end
      vim.t.message_bufnr = nil
    end
  end,
}

return message_buffer
