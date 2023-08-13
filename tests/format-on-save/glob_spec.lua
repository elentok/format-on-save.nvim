local glob = require("format-on-save.glob")

describe("glob", function()
  describe("findglob", function()
    it("searches upwards for the given pattern", function()
      local start_path = vim.fn.fnamemodify("lua/format-on-save/error-notifiers/init.lua", ":p")
      local result = glob.find("stylua.*", start_path)
      local expected = vim.loop.cwd() .. "/stylua.toml"

      assert.is.same(expected, result)
    end)

    it("finds file inside the stop path", function()
      local start_path = vim.fn.fnamemodify("lua/format-on-save/error-notifiers/init.lua", ":p")
      local stop_path = vim.fn.fnamemodify("lua", ":p")
      local result = glob.find("stylua.*", start_path, { stop_path = stop_path })

      assert.is.same(nil, result)
    end)

    it("fails to find file outside of the stop path", function()
      local start_path = vim.fn.fnamemodify("lua/format-on-save/error-notifiers/init.lua", ":p")
      local stop_path = vim.loop.cwd()
      local result = glob.find("stylua.*", start_path, { stop_path = stop_path })

      assert.is.same(vim.fn.fnamemodify("stylua.toml", ":p"), result)
    end)
  end)
end)
