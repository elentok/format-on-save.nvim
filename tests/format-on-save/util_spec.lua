local config = require("format-on-save.config")
local util = require("format-on-save.util")

local original_exclude_path_patterns = config.exclude_path_patterns

describe("util", function()
  describe("is_path_excluded", function()
    before_each(function()
      config.exclude_path_patterns = { "/excluded/path/" }
    end)

    after_each(function()
      config.exclude_path_patterns = original_exclude_path_patterns
    end)

    it("is true when path is excluded", function()
      assert.is.same(true, util.is_path_excluded("/src/excluded/path/file"))
    end)

    it("is false when path is not excluded", function()
      assert.is.same(false, util.is_path_excluded("/src/not-excluded/path/file"))
    end)
  end)
end)
