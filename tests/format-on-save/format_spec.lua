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
  describe("custom formatter", function()
    it("formats the buffer", function()
      vim.cmd("new")
      vim.fn.setline(1, "hello {name}")
      format(test_formatter)

      assert.is.same("hello bob", vim.fn.getline(1))
    end)
  end)

  describe("shell formatter", function()
    it("formats the buffer", function()
      vim.cmd("new")
      vim.fn.setline(1, "hello {name}")
      format(formatters.shell({
        cmd = { "./tests/dummy-formatter.sh", "replace-name" },
      }))

      assert.is.same("hello joe", vim.fn.getline(1))
    end)

    it("expands % to the filename", function()
      vim.cmd("new")
      vim.cmd("file myfile")
      vim.fn.setline(1, "filename={filename}")
      format(formatters.shell({
        cmd = { "./tests/dummy-formatter.sh", "replace-filename", "%" },
      }))

      assert.is.same("filename=myfile", vim.fn.getline(1))
    end)

    it("supports formatters that don't support stdin", function()
      vim.cmd("new")
      vim.cmd("file mytempfile")
      vim.fn.setline(1, "filename={tempfile}")
      format(formatters.shell({
        cmd = { "./tests/dummy-formatter.sh", "format-tempfile", "%" },
        tempfile = function()
          return "test-tempfile"
        end,
      }))

      assert.is.same("filename=test-tempfile", vim.fn.getline(1))
    end)

    it("accepts a function as the 'cmd' argument", function()
      vim.cmd("new")
      vim.fn.setline(1, "filename={filename}")
      format(formatters.shell({
        cmd = function()
          return { "./tests/dummy-formatter.sh", "replace-filename", "BOB" }
        end,
      }))

      assert.is.same("filename=BOB", vim.fn.getline(1))
    end)
  end)
end)
