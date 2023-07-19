local systemlist = require("format-on-save.systemlist")

describe("systemlist", function()
  it("handles successful run with stdout-only", function()
    local result = systemlist({ "echo", "Hello\\\\nWorld" })
    assert.are.same({
      stdout = { "Hello", "World" },
      stderr = {},
      exitcode = 0,
    }, result)
  end)

  it("handles successful run with both stdout and stderr", function()
    local result = systemlist("echo Hello\\\\nWorld && (>&2 echo My Error)")
    assert.are.same({
      stdout = { "Hello", "World" },
      stderr = { "My Error" },
      exitcode = 0,
    }, result)
  end)

  it("handles failed run with both stdout and stderr", function()
    local result = systemlist("(>&2 echo My Error) && (echo Hello\\\\nWorld) && exit 3")
    assert.are.same({
      stdout = { "Hello", "World" },
      stderr = { "My Error" },
      exitcode = 3,
    }, result)
  end)

  it("handles failed run with only stderr", function()
    local result = systemlist("(>&2 echo My Error) && exit 3")
    assert.are.same({
      stdout = {},
      stderr = { "My Error" },
      exitcode = 3,
    }, result)
  end)
end)
