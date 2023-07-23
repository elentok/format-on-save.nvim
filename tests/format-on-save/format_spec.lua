local format = require("format-on-save.format")
local formatters = require("format-on-save.formatters")

local test_formatter = formatters.custom({
  format = function(lines)
    return vim.tbl_map(function(line)
      return line:gsub("{name}", "bob")
    end, lines)
  end,
})

describe("format", function()
  vim.cmd("new")
  vim.fn.setline(1, "hello {name}")
  format(test_formatter)

  assert.is.same("hello bob", vim.fn.getline(1))
end)
