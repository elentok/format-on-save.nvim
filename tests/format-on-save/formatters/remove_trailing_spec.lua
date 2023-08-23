local remove_trailing = require("format-on-save.formatters.remove-trailing")

describe("remove_trailing.whitespace", function()
  it("removes trailing whitespace", function()
    local formatted = remove_trailing.whitespace.format({
      "line1  ",
      "line2    ",
      "   ",
    })
    assert.is.same({ "line1", "line2", "" }, formatted)
  end)
end)

describe("remove_trailing.newlines", function()
  it("removes nothing when there are no trailing newlines", function()
    local formatted = remove_trailing.newlines.format({
      "hello",
      "world",
    })
    assert.is.same({ "hello", "world" }, formatted)
  end)

  it("removes trailing newlines (two lines)", function()
    local formatted = remove_trailing.newlines.format({
      "hello",
      "world",
      "",
      "",
    })
    assert.is.same({ "hello", "world" }, formatted)
  end)

  it("removes trailing newlines (one line)", function()
    local formatted = remove_trailing.newlines.format({
      "hello",
      "world",
      "",
    })
    assert.is.same({ "hello", "world" }, formatted)
  end)
end)
