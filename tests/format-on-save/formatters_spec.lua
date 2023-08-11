local formatters = require("format-on-save.formatters")

describe("formatters", function()
  describe("if_file_exists", function()
    describe("when file exists", function()
      it("returns the formatter", function()
        local lazy_formatter = formatters.if_file_exists("stylua.*", formatters.shfmt)

        vim.cmd("e ./tests/dummy-file")
        assert.is.same(formatters.shfmt, lazy_formatter())
      end)
    end)

    describe("when file does not exist", function()
      it("returns the formatter", function()
        local lazy_formatter = formatters.if_file_exists("asdfaasdf.*", formatters.shfmt)

        vim.cmd("e ./tests/dummy-file")
        assert.is.same(nil, lazy_formatter())
      end)
    end)

    it("supports multiple patterns", function()
      local lazy_formatter = formatters.if_file_exists({ "nonono.*", "stylua.*" }, formatters.shfmt)

      vim.cmd("e ./tests/dummy-file")
      assert.is.same(formatters.shfmt, lazy_formatter())
    end)
  end)
end)
