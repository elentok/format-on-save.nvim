local config = require("format-on-save.config")
local update_buffer = require("format-on-save.update-buffer")

local original_partial_update = config.experiments.partial_update

describe('update-buffer with partial_update == "diff"', function()
  before_each(function()
    config.experiments.partial_update = "diff"
  end)

  after_each(function()
    config.experiments.partial_update = original_partial_update
  end)

  it("properly handles empty hunk in a unified diff", function()
    local original_lines = {
      "{",
      "",
      "1;",
      "",
      "2;",
      "}",
    }

    local formatted_lines = {
      "{",
      "  1;",
      "",
      "  2;",
      "}",
    }

    vim.cmd("new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, original_lines)

    update_buffer(original_lines, formatted_lines)

    assert.are.same(formatted_lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)
end)
