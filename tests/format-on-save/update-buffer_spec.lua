local config = require("format-on-save.config")
local update_buffer = require("format-on-save.update-buffer")

local original_partial_update = config.experiments.partial_update
local original_adjust_cursor_position = config.experiments.adjust_cursor_position

describe(
  'update_buffer with partial_update == "diff" and adjust_cursor_position == true',
  function()
    before_each(function()
      config.experiments.partial_update = "diff"
      config.experiments.adjust_cursor_position = true
    end)

    after_each(function()
      config.experiments.partial_update = original_partial_update
      config.experiments.adjust_cursor_position = original_adjust_cursor_position
    end)

    it("moves cursor to a proper position in each window for a buffer", function()
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
      vim.api.nvim_win_set_cursor(0, { 5, 0 })

      vim.cmd("vsplit")
      vim.api.nvim_win_set_cursor(0, { 5, 1 })

      vim.cmd("vsplit")
      vim.api.nvim_win_set_cursor(0, { 3, 0 })

      update_buffer(original_lines, formatted_lines)
      assert.are.same(formatted_lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))

      assert.are.same({ 2, 2 }, vim.api.nvim_win_get_cursor(0))
      vim.cmd("quit")

      assert.are.same({ 4, 3 }, vim.api.nvim_win_get_cursor(0))
      vim.cmd("quit")

      assert.are.same({ 4, 2 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("places cursor after deleted range if cursor was inside", function()
      local original_lines = {
        "if (Math.random() > 0.5) {",
        "console.",
        "",
        "log('something');",
        "}",
      }

      local formatted_lines = {
        "if (Math.random() > 0.5) {",
        "  console.log('something');",
        "}",
      }

      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, original_lines)
      vim.api.nvim_win_set_cursor(0, { 3, 0 })

      update_buffer(original_lines, formatted_lines)
      assert.are.same(formatted_lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))

      assert.are.same({ 2, 10 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("leaves cursor on the same position if a character it stays on was replaced", function()
      local original_lines = {
        "local x = print('some string')",
      }

      local formatted_lines = {
        "local x = print 'some string'",
      }

      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, original_lines)
      vim.api.nvim_win_set_cursor(0, { 1, 15 })

      update_buffer(original_lines, formatted_lines)
      assert.are.same(formatted_lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))

      assert.are.same({ 1, 15 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("moves cursor to proper position when single line is being split into multiple", function()
      local original_lines = {
        "{ 123; 456; 789; }",
      }

      local formatted_lines = {
        "{",
        "  123;",
        "  456;",
        "  789;",
        "}",
      }

      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, original_lines)
      vim.api.nvim_win_set_cursor(0, { 1, 8 })

      update_buffer(original_lines, formatted_lines)
      assert.are.same(formatted_lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))

      assert.are.same({ 3, 3 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("properly positions cursor whenever a line break is added above cursor", function()
      local original_lines = {
        "{",
        "123; 456;",
        "789;",
        "}",
      }

      local formatted_lines = {
        "{",
        "  123;",
        "  456;",
        "  789;",
        "}",
      }

      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, original_lines)
      vim.api.nvim_win_set_cursor(0, { 3, 1 })

      update_buffer(original_lines, formatted_lines)
      assert.are.same(formatted_lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))

      assert.are.same({ 4, 3 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("handles an empty added region when cursor is repositioned", function()
      local original_lines = {
        "   if (!foobar ||",
        "     !foobar.baz) { return; }",
      }

      local formatted_lines = {
        " if (!foobar || !foobar.baz) {",
        "   return;",
        " }",
      }

      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, original_lines)
      vim.api.nvim_win_set_cursor(0, { 2, 8 })

      update_buffer(original_lines, formatted_lines)
      assert.are.same(formatted_lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))

      assert.are.same({ 1, 19 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("refines edits when vim.diff may not be enough", function()
      local original_lines = {
        "const c = a+",
        "  b;",
      }

      local formatted_lines = {
        "const c = a + b;",
      }

      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, original_lines)
      vim.api.nvim_win_set_cursor(0, { 1, 11 })

      update_buffer(original_lines, formatted_lines)
      assert.are.same(formatted_lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))

      assert.are.same({ 1, 12 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("adjusts cursor properly if it happens to be inside of deleted range at eof", function()
      local original_lines = {
        'print("Hello World")',
        "",
      }

      local formatted_lines = {
        "print 'Hello World'",
      }

      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, original_lines)
      vim.api.nvim_win_set_cursor(0, { 2, 0 })

      update_buffer(original_lines, formatted_lines)
      assert.are.same(formatted_lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))

      assert.are.same({ 1, 18 }, vim.api.nvim_win_get_cursor(0))
    end)
  end
)
