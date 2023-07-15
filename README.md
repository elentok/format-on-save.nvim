# format-on-save.nvim

Automatically formats files when saving using either LSP or shell utilities like prettierd or shfmt.

It also restores the cursor of any window showing the current file (useful when
editing the same file in a split).

NOTE: This is a work in progress and the API might change.

## TODO

- [x] Add LazyFormatter - a function that is only called while formatting and
      returns a formatter
- [ ] Add CustomFormatter - a function that gets an array of lines and returns
      a new array of lines
- [ ] Support concatenating formatters
- [ ] File size limit / Line count limit - to avoid hanging on files that are
      too big (add a :ForceFormat command and notify the user why formatting was
      skipped)
- [x] Use vim.notify to show error messages
- [ ] Support formatters that don't work with stdin by writing to a temp file
      first
- [ ] Add LSP timeout to configuration
- [ ] Shell formatter - when the result is the same as the input don't modify
      the buffer

## formatters

There are currently 3 types of formatters:

- **LspFormatter** - uses `vim.lsp.buf.format` to format the file, you can pass
  a `client_name` option to use a specific client in case there are several ones
  that support formatting.
- **ShellFormatter** - passes the current buffer via stdin to a shell program (like `prettierd`
  or `shfmt`) and replaces the buffer's contents with the result.
- **LazyFormatter** - a function that is called lazily every time we format the
  file, this allows using a different formatter for different files.

## Installation

Add the following to your package manager:

```lua
{ "elentok/format-on-save.nvim" },
```

## Configuration

By default this plugin doesn't enable any format on save, you have to specify
what you want:

```lua
local format_on_save = require("format-on-save")
local formatters = require("format-on-save.formatters")

format_on_save.setup({
  exclude_path_patterns = {
    "/node_modules/",
    ".local/share/nvim/lazy",
  },
  formatter_by_ft = {
    css = formatters.lsp,
    html = formatters.lsp,
    java = formatters.lsp,
    javascript = formatters.lsp,
    json = formatters.lsp,
    lua = formatters.lsp,
    markdown = formatters.prettierd,
    openscad = formatters.lsp,
    python = formatters.black,
    rust = formatters.lsp,
    scad = formatters.lsp,
    scss = formatters.lsp,
    sh = formatters.shfmt,
    terraform = formatters.lsp,
    typescript = formatters.prettierd,
    typescriptreact = formatters.prettierd,
    yaml = formatters.lsp,

    -- Add your own shell formatters:
    myfiletype = formatters.shell({ cmd = { "myformatter", "%" } }),

    -- Add lazy formatter that will only run when formatting:
    my_custom_formatter = function()
      if vim.api.nvim_buf_get_name(0):match("/README.md$") then
        return formatters.prettierd
      else
        return formatters.lsp()
      end
    end
  },
})
```

By default it will add the `BufWritePre` and `BufWritePost` autocommands and the `Format`,
`FormatOn` and `FormatOff` user commands. If you prefer to avoid it and define
your own you can disable it:

```lua
require('format-on-save').setup({
  auto_commands = false,
  user_commands = false,
})
```

To trigger the format call:

```lua
require('format-on-save').format()
```

To restore the cursor positions after the format:

```lua
require('format-on-save').restore_cursors()
```
