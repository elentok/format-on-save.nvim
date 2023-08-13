local formatters = require("format-on-save.formatters")

describe("if_file_exists", function()
  describe("when file exists", function()
    it("returns the formatter", function()
      local lazy_formatter = formatters.if_file_exists({
        pattern = "stylua.*",
        formatter = formatters.shfmt,
      })

      vim.cmd("e ./tests/dummy-file")
      assert.is.same(formatters.shfmt, lazy_formatter())
    end)
  end)

  describe("when file does not exist", function()
    it("returns the formatter", function()
      local lazy_formatter = formatters.if_file_exists({
        pattern = "asdfaasdf.*",
        formatter = formatters.shfmt,
      })

      vim.cmd("e ./tests/dummy-file")
      assert.is.same(nil, lazy_formatter())
    end)
  end)

  it("supports multiple patterns", function()
    local lazy_formatter = formatters.if_file_exists({
      pattern = { "nonono.*", "stylua.*" },
      formatter = formatters.shfmt,
    })

    vim.cmd("e ./tests/dummy-file")
    assert.is.same(formatters.shfmt, lazy_formatter())
  end)

  it("supports stop path", function()
    local lazy_formatter = formatters.if_file_exists({
      pattern = { "nonono.*", "stylua.*" },
      formatter = formatters.stylua,
      stop_path = function()
        return vim.fn.fnamemodify("tests", ":p")
      end,
    })

    vim.cmd("e ./tests/dummy-file")
    assert.is.same(nil, lazy_formatter())
  end)
end)
