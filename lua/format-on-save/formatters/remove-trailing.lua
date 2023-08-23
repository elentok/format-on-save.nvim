local create = require("format-on-save.formatters.create")

local whitespace = create.custom({
  format = function(lines)
    return vim.tbl_map(function(line)
      return line:gsub("%s*$", "")
    end, lines)
  end,
})

local newlines = create.custom({
  format = function(lines)
    local count_newlines = 0
    for i = #lines, 1, -1 do
      local line = lines[i]
      if line == "" then
        count_newlines = count_newlines + 1
      else
        break
      end
    end

    return vim.list_slice(lines, 0, #lines - count_newlines)
  end,
})

return { whitespace = whitespace, newlines = newlines }
