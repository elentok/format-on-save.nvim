local create = require("format-on-save.formatters.create")

local whitespace = create.custom({
  format = function(lines)
    return vim.tbl_map(function(line)
      return line:gsub("%s*$", "")
    end, lines)
  end,
})

return { whitespace = whitespace }
