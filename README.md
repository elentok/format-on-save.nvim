# format-on-save.nvim

Automatically formats files when saving using either LSP or shell utilities like prettierd or shfmt.

It also restores the cursor of any window showing the current file (useful when
editing the same file in a split).

NOTE: This is a work in progress and the API might change.

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
