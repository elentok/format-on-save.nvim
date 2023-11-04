# format-on-save.nvim

Automatically formats files when saving using either LSP or shell utilities like prettierd or shfmt.

It also restores the cursor of any window showing the current file (useful when
editing the same file in a split).

NOTE: This is a work in progress and the API might change.

## Why another formatting plugin?

Until now I've used LSP-only formatting with a simple auto command with null-ls
to cover non-LSP formatters. However, now that null-ls is being archived I
needed to find an alternative.

I tried several plugins but:

- Neither supported both LSP and non-LSP formatters
- Some of them format asynchronously which is tricky because you need to lock
  the buffer before formatting and there are a lot of edge cases.
- Some of them support partial formatting which adds a lot of complexity.

This plugin has a few core principles to keep it simple:

- **Synchronous formatting** - Most of the formatters I use are quite fast and
  the delay isn't noticeable to me.
- **Format on save only** (no partial formatting) - There's a `:Format` command
  you can call whenever you want but the purpose of this plugin is to format when
  saving.

## TODO

- [x] Add LazyFormatter - a function that is only called while formatting and
      returns a formatter
- [x] Add CustomFormatter - a function that gets an array of lines and returns
      a new array of lines
- [x] Support concatenating formatters
- [ ] File size limit / Line count limit - to avoid hanging on files that are
      too big (add a :ForceFormat command and notify the user why formatting was
      skipped)
- [x] Use vim.notify to show error messages
- [x] Support formatters that don't work with stdin by writing to a temp file
      first
- [ ] Add LSP timeout to configuration
- [ ] Shell formatter - when the result is the same as the input don't modify
      the buffer
- [ ] When non-LSP formatter fails (non-zero exitcode) show the error in a nicer
      way (readonly message buffer, notification or popup).
- [ ] Look into using vim.diff() to make the partial update smarter (only update
      lines that actually changed)

## Formatters

There are currently 3 types of formatters:

- **LspFormatter** - uses `vim.lsp.buf.format` to format the file, you can pass
  a `client_name` option to use a specific client in case there are several ones
  that support formatting.
- **ShellFormatter** - passes the current buffer via stdin to a shell program (like `prettierd`
  or `shfmt`) and replaces the buffer's contents with the result.
  - For formatters that don't support stdin you can pass a `tempfile` field
    which can be either `"random"` (uses `vim.fn.tempname()`) or a function that
    returns a string to be used as the tempfile and then the plugin will write the
    buffer to this file, run the command on it (the "%" value will be expanded to
    the tempfile) and read it back and fill in the buffer).
  - The first item in the `cmd` array will be expanded by default using the `vim.fn.exepath`
    function in order to detect mason binaries. To opt-out set the `expand_executable`
    field to `false`.
  - The `cmd` argument can also be a function that is evaluated each time we format.
- **CustomFormatter** - passes the lines of the current buffer through a
  function that modifies them and then updates the contents.
- **LazyFormatter** - a function that is called lazily every time we format the
  file, this allows using a different formatter for different files.

## Experimental features

### Partial update

When updating all of the lines in a buffer all of the extmarks get removed. This
plugin currently includes two experimental methods to only partially update the
buffer:

1. `experiments.partial_update = 'line-by-line'` - a very simple algorithm that
   goes line-by-line and compares them, only updates modified lines.
1. `experiments.partial_update = 'diff'` - an awesome upgrade added by @faergeek
   that uses `vim.diff` to compare the old and new buffer lines and only update
   the modified hunks.

You can enable either of them like this:

```lua
require('format-on-save').setup({
  experiments = {
    partial_update = 'diff', -- or 'line-by-line'
  }
})
```

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
    end,

    -- Add custom formatter
    filetype1 = formatters.remove_trailing_whitespace,
    filetype2 = formatters.custom({ format = function(lines)
      return vim.tbl_map(function(line)
        return line:gsub("true", "false")
      end, lines)
    end}),

    -- Concatenate formatters
    python = {
      formatters.remove_trailing_whitespace,
      formatters.shell({ cmd = "tidy-imports" }),
      formatters.black,
      formatters.ruff,
    },

    -- Use a tempfile instead of stdin
    go = {
      formatters.shell({
        cmd = { "goimports-reviser", "-rm-unused", "-set-alias", "-format", "%" },
        tempfile = function()
          return vim.fn.expand("%") .. '.formatter-temp'
        end
      }),
      formatters.shell({ cmd = { "gofmt" } }),
    },

    -- Add conditional formatter that only runs if a certain file exists
    -- in one of the parent directories.
    javascript = {
      formatters.if_file_exists({
        pattern = ".eslintrc.*",
        formatter = formatters.eslint_d_fix)
      }),
      formatters.if_file_exists({
        pattern = { ".prettierrc", ".prettierrc.*", "prettier.config.*" },
        formatter = formatters.prettierd,
      }),
      -- By default it stops at the git repo root (or "/" if git repo not found)
      -- but it can be customized with the `stop_path` option:
      formatters.if_file_exists({
        pattern = ".prettierrc",
        formatter = formatters.prettierd,
        stop_path = function()
          return "/my/custom/stop/path"
        end
      }),
    },
  },

  -- Optional: fallback formatter to use when no formatters match the current filetype
  fallback_formatter = {
    formatters.remove_trailing_whitespace,
    formatters.remove_trailing_newlines,
    formatters.prettierd,
  },

  -- By default, all shell commands are prefixed with "sh -c" (see PR #3)
  -- To prevent that set `run_with_sh` to `false`.
  run_with_sh = false,
})
```

### Error messages

By default the plugin uses another buffer to show error messages, you can
customize it by setting the `error_notifier` configuration flag, e.g. to use
`vim.notify()`:

```lua
local format_on_save = require("format-on-save")
local vim_notify = require("format-on-save.error-notifiers.vim-notify")

format_on_save.setup({
  error_notifier = vim_notify,
})
```

Alternatively you can implement your own:

```lua
local format_on_save = require("format-on-save")

---@type ErrorNotifier
local error_notifier = {
  show = function(opts)
    -- use opts.title and opts.body
  end,
  hide = function()
    -- hide the error when it's been resolved
  end,
}

format_on_save.setup({
  error_notifier = error_notifier,
})
```

### Disable warning when formatter is successful but wrote to stderr

When a formatter exits with exitcode 0 but its stderr has contents we show a
warning message (via `vim.notify`).

The default level is `vim.log.levels.WARN`. To disable this message entirely set
the `stderr_loglevel` config key to `vim.log.levels.OFF`:

```lua
require('format-on-save').setup({
  stderr_loglevel = vim.log.levels.OFF,
})
```

### Disable auto commands and user commands

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
