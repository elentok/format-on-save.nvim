---@type ErrorNotifier
local vim_notify = {
  show = function(opts)
    local body = opts.body
    if type(body) ~= "string" then
      body = table.concat(body, "\n")
    end

    vim.notify(body, vim.log.levels.ERROR, { title = opts.title })
  end,

  hide = function()
    -- Haven't looked into how to hide vim notifications yet,
    -- I'm not sure if it's possible.
  end,
}

return vim_notify
