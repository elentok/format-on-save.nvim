local root_dir = vim.fn.fnamemodify(vim.trim(vim.fn.system("git rev-parse --show-toplevel")), ":p")
package.path = string.format("%s;%s?.lua;%s?/init.lua", package.path, root_dir, root_dir)
vim.opt.packpath:prepend(string.format("%s", root_dir .. ".testcache/site"))
vim.opt.rtp = {
  root_dir,
  vim.env.VIMRUNTIME,
}

vim.cmd([[
  filetype on
  packadd plenary.nvim
]])

vim.opt.swapfile = false

-- vim.cmd([[
--   runtime plugin/neo-tree.vim
-- ]])

-- For debugging
P = function(...)
  print(unpack(vim.tbl_map(vim.inspect, { ... })))
end
