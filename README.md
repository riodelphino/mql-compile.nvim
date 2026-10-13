# mql-compile.nvim

![img/logo.jpg](img/logo.jpg)

A neovim plugin for compiling MQL5/MQL4 scripts asyncronously.  
Without heavy MetaEditor GUI. (Compiling on command-line).

https://github.com/user-attachments/assets/0029ee53-0812-4c58-ae9e-ce970ca5bb4d
(Sorry, this demo movie was recorded with an older version.)

with [nvim-notify](https://github.com/rcarriga/nvim-notify) & [nvim-pqf](https://github.com/yorickpeterse/nvim-pqf)

> [!Note]
> Tested for years in MacOS with WineSkin and Sikarugir.
> Use it at your own risk. Backup your files before testing.

> [!Warning]
> Need tested in Windows or Linux  

Now ensured to work only in:
- macOS + Sikarugir
- macOS + WineSkin

Please test & [create issues](https://github.com/riodelphino/mql-compile.nvim/issues/new) on GitHub.

## Breaking Changes

### v0.8.0
- Removed `send.targets` option. Return the path(s) from `send.to(ctx)` instead. (See [Send](#send))

### v0.6.0
- Deprecate `rename.get_custom_path()` option, use `rename.to()` with `ctx` table arg instead.

### v0.5.0 - 0.5.1
- Show `ui.select` with found source files list, instead of auto-detection.
- Removed `opts.detect` option.
- Removed `:MQLSetSource` command and `set_source()` API.

### v0.4.0
Changed the config structure

Before (< `v0.3.6`):
```lua
opts = {
   compile = {
      wine = {
         enabled = true,
         command = '',
      },
      overwrite = true,
   },
}
```

After (> `v0.4.0`):
```lua
opts = {
   ft = {
      mql5 = {
         wine_path = '', -- wine command path. (leave it '' on windows)
         overwrite = true,
      },
      mql4 = {
         wine_path = '', -- wine command path. (leave it '' on windows)
         overwrite = true,
      },
   },
}
```
This enables switching wine path between mql5 and mql4.


## Features

**Main features**
- Async compiling MQL5/MQL4
- Show quickfix
- Select source file to compile
- Customizable target path (place compiled files wherever you prefer)
- Version management
- Project specific options
- Send compiled files to other directories (e.g. VPS shared folder, MT4/MT5 apps)
- Hooks (`pre` / `post` compiling)
- Works on `macOS + WineSkin` and `macOS + Sikarugir` for now

**Not implemented**
- Works on Windows ? (Need tested)
- Works on Linux ? (Need tested)


## Requirements

**Mandatory**
- nvim > v0.10.2
- MT5 or MT4 installed:
   - Windows: Install directly
   - Linux and macOS: Install via Sikarugir or WineSkin
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for async

**Optional plugins**
- Filetype:
   - [mql-filetype.nvim](https://github.com/riodelphino/mql-filetype.nvim) Set filetypes and Apply parsers for `*.mq5|*.mq4|*.mqh`
- Notify:
   - [nvim-notify](https://github.com/rcarriga/nvim-notify) Cool style notify messages
- Quickfix:
   - [quicker.nvim](https://github.com/stevearc/quicker.nvim) Beautify qflist
   - [nvim-pqf](https://github.com/yorickpeterse/nvim-pqf) Beautify qflist
   - [qfpreview.nvim](https://github.com/r0nsha/qfpreview.nvim) Floating preview window
   - [nvim-bqf](https://github.com/kevinhwang91/nvim-bqf) Floating preview window and beautify qflist


## Installation

Using [Lazy.nvim](https://github.com/folke/lazy.nvim):

with Sikarugir:
```lua
-- Minimum config:
return {
   'riodelphino/mql-compile.nvim',
   dependencies = {
      'nvim-lua/plenary.nvim',
      'riodelphino/mql-filetype.nvim', -- optional
      'rcarriga/nvim-notify', -- optional
      'kevinhwang91/nvim-bqf', -- optional
      'yorickpeterse/nvim-pqf', -- optional
   },
   lazy = true,
   ft = { 'mql5', 'mql4' }, -- NOTE: Recommend `mql-filetype.nvim` to apply `mql5|mql4` filetypes to `*.mq5|*.mq4|*.mqh` files
   opts = {
      ft = {
         mql5 = {
            wine_path = '~/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine',
            metaeditor_path = '~/Applications/MetaTrader 5.app/Contents/SharedSupport/prefix/drive_c/Program Files/MetaTrader 5/MetaEditor64.exe'
         },
         mql4 = {
            wine_path = '~/Applications/MetaTrader 4.app/Contents/SharedSupport/wine/bin/wine',
            metaeditor_path = '~/Applications/MetaTrader 4.app/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/MetaTrader 4/MetaEditor.exe'
         },
      },
   },
   keys = {},
   cmd = { 'MQLCompile', 'MQLCompileShowOptions' },
}
```

## Default options

```lua
opts = {
   root_marker = { '.editorconfig', '.gitignore', '.git', '.clangd', '.clang-format', 'cpplint.cfg' },
   ft = {
      mql5 = {
         metaeditor_path = '', -- wine command path. (leave it '' on windows)
         include_path = '', -- Not supported now
         extension = {
            source = 'mq5',
            compiled = 'ex5',
         },
         overwrite = true,
      },
      mql4 = {
         metaeditor_path = '', -- wine command path. (leave it '' on windows)
         include_path = '', -- Not supported now
         extension = {
            source = 'mq4',
            compiled = 'ex4',
         },
         overwrite = true,
      },
   },
   log = {
      extension = 'log',
      delete_after_load = true,
   },
   quickfix = {
      types = { 'error', 'warning' }, -- Types to pick up. 'error' | 'warning' | 'information'
      show = {
         copen = true, -- Open quickfix automatically
         with = { 'error', 'warning' }, -- Types to copen. 'error' | 'warning' | 'information'
      },
      parse = nil, -- See '# Parsing quickfix' section
   },
   information = {
      actions = { 'including' }, -- Actions to pick up. 'compiling' | 'including'
      show = {
         notify = true, -- Show 'information' independently in notify
         with = { 'including' }, -- Actions to show. 'compiling' | 'including'
      },
      parse = nil, -- See '# Parsing and formatting information' section
      format = nil, -- See '# Parsing and formatting information' section
   },
   rename = {
      enabled = true,
      ---@param ctx mql_compile.Ctx
      to = function(ctx) -- See '# Ctx' section
         if ctx.ver == nil or ctx.ver == '' then
            return string.format('archive/%s.%s', ctx.fname, ctx.ext) -- archive/myea.ex5
         else
            return string.format('archive/%s_v%s.%s', ctx.fname, ctx.ver, ctx.ext) -- archive/myea_ver1.10.ex5
         end
      end,
   },
   send = { -- See '# Send' section
      enabled = false,
      to = function(ctx) return nil end, -- Return path(s) to send to
   },
   hooks = { -- See '# Hooks' section
      pre = nil, -- function(ctx) ... end
      post = nil, -- function(ctx) ... end
   },
   notify = { -- Enable/disable notify
      debug = { -- For debug
         compile = {
            show_cmd = false,
            show_cwd = false,
         },
      },
      compile = {
         on_started = true,
         on_finished = true,
      },
      log = {
         on_saved = false,
         on_deleted = false,
      },
      quickfix = {
         on_finished = true, -- Add quickfix counts to main message on 'notify.compile.on_finished'
      },
      information = {
         on_generated = true, -- Show informations on notify
      },
      rename = {
         on_mkdir = false,
         on_version = false,
         on_renamed = true,
      },
      send = {
         on_mkdir = false,
         on_sent = true,
      },
      levels = { -- Color to notify if compiling was ...
         succeeded = { -- with type ...
            none = vim.log.levels.INFO,
            info = vim.log.levels.INFO,
            warn = vim.log.levels.WARN, -- *.INFO is also good, if you don't like warn color on success.
         },
         failed = vim.log.levels.ERROR,
         information = vim.log.levels.INFO, -- for notifing informations
      },
      show_title = false,
   },
   highlights = { -- Highlights & syntax on quickfix window
      enabled = true,
      hl_prefix = 'qf', -- prefix for hlgroup
      hl_groups = nil, -- See '# Highlights' section
   },
},
```


## Default 'metaeditor_path'

Set paths of MetaEditor executables on `opts.ft.mql5` and `opts.ft.mql4`.  
(It depends on your settings on installing.)


### MT5

macOS: (When the app name is `MetaTrader 5.app`)
```lua
-- via Sikarugir
metaeditor_path = '~/Applications/MetaTrader 5.app/Contents/SharedSupport/prefix/drive_c/Program Files/MetaTrader 5/MetaEditor64.exe'
-- via WineSkin
metaeditor_path = '~/Applications/Wineskin/MetaTrader 5.app/drive_c/Program Files/MetaTrader 5/MetaEditor64.exe'
```
Windows (NOT TESTED):
```lua
metaeditor_path = 'C:\\Program Files\\MetaTrader 5\\MetaEditor64.exe'
```

### MT4

macOS: (When the app name is `MetaTrader 4.app`)
```lua
-- via Sikarugir
metaeditor_path = '~/Applications/MetaTrader 4.app/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/MetaTrader 4/MetaEditor.exe'
-- via WineSkin
metaeditor_path = '~/Applications/Wineskin/MetaTrader 4.app/drive_c/Program Files (x86)/MetaTrader 4/metaeditor.exe'
```
Windows (NOT TESTED):
```lua
metaeditor_path = 'C:\\Program Files (x86)\\MetaTrader 4\\metaeditor.exe'
```


## Parsing and formatting

You can modify parsing & formatting functions, if you need.  
Leave 'parse' or 'format' as nil to use these default functions. 


### Parsing quickfix

This is the parsing function, from log to quickfix
Default:
```lua
opts = {
   quickfix = {
      parse = function(line, type)
         local e = {}
         if type == 'error' or type == 'warning' then
            e.filename, e.lnum, e.col, e.type, e.nr, e.text = line:match('^(.*)%((%d+),(%d+)%) : (.*) (%d+): (.*)$')
         elseif type == 'information' then
            e.filename, e.type, e.text = line:match('^(.*) : (.*): (.*)$')
            e.lnum = 1
            e.col = 1
            e.nr = 0
         end
         e.type = e.type:sub(1, 1):upper() -- Convert type to E/W/I/H/N
         return e
      end,
   },
},
```

### Parsing and formatting information

This is the parsing and formatting function, from log to information

Default:
```lua
opts = {
   information = {
      parse = function(line)
         local i = {}
         i.file, i.type, i.action, i.details = line:match('^(.-) : (%w+): (%w+) (.+)')
         return i
      end,
      format = function(i)
         local formated = string.format('%s %s', i.action, i.details)
         return formated
      end,
   },
},

```

### Rename (Custom destination path)

The paths where the compiled `*.ex[45]` files are placed are modifiable.  

for example:
- Add version to the file
- Move the file to `archive` directory

Default:
```lua
opts = {
   rename = {
     enabled = true, -- set false for using default path by metaeditor
     ---@param ctx mql_compile.Ctx
     to = function(ctx)
       if ctx.ver == nil or ctx.ver == '' then
         return string.format('archive/%s.%s', ctx.fname, ctx.ext) -- archive/myea.ex5
       else
         return string.format('archive/%s_v%s.%s', ctx.fname, ctx.ver, ctx.ext) -- archive/myea_ver1.10.ex5
       end
     end,
   },
},
```
`rename.to` receives a `ctx` table. See [Ctx](#ctx) section.

#### Rename Example

source file: `/Users/username/projects/ea/myea.mq5`

```cpp
#property version "1.23"
```

Then, `rename.to` callback recieves following args in ctx table.
| Name         | Content                | Example                     |
| ------------ | ---------------------- | --------------------------- |
| root         | project root (.git)    | /Users/username/projects/ea |
| project      | project name           | ea                          |
| ft           | filetype               | mql5                        |
| src_path     | source path            | src/myea.mq5                |
| dir          | dir                    | src                         |
| base         | basename (with ext)    | myea.mq5                    |
| fname        | filename (without ext) | myea                        |
| ext          | compiled extension     | ex5                         |
| ext_src      | source extension       | mq5                         |
| ver          | version                | 1.23                        |
| major        | major version          | 1                           |
| minor        | minor version          | 23                          |
| kind         | program type           | expert                      |
| kind_dirname | kind's directory name  | Experts                     |


The paths out of project-root are also available.
```lua
-- Relative path
return string.format(root .. '/../../archive/%s.%s', fname, ext)
-- Absolute path
return string.format('/path/to/archive/%s.%s', fname, ext)
```

## Send

Send (copy) the compiled `*.ex[45]` file to other directories after compiling successfully.  
(e.g. A shared folder for VPS, `MQL5/Experts` dirs of your MT4/MT5 apps)

- `send.enabled`: Enable sending
- `send.to(ctx)`: Returns the path (string) or paths (table) to send to. (`~` is expanded) Return `nil` to send nothing.

Default:
```lua
opts = {
   send = {
      enabled = false,
      ---@param ctx mql_compile.ResultCtx
      ---@return string|string[]|nil
      to = function(ctx) return nil end,
   },
},
```

To keep your environment-specific paths out of the repository, set `send.to` in your global config, and only `send = { enabled = true }` in each project's `.mql-compile.lua`.

Global config:
```lua
local send_dirs = {
   mql4 = { '~/VPS/shared/MQL4', '~/Applications/MT4.app/drive_c/Program Files (x86)/MetaTrader 4/MQL4' },
   mql5 = { '~/VPS/shared/MQL5', '~/Applications/MT5.app/drive_c/Program Files/MetaTrader 5/MQL5' },
}

opts = {
   send = {
      to = function(ctx)
         if not ctx.kind_dirname then return nil end -- Skip unknown kinds
         local paths = {}
         for _, dir in ipairs(send_dirs[ctx.ft]) do
            -- e.g. <dir>/Experts/yourname/myea.ex5
            table.insert(paths, vim.fs.joinpath(dir, ctx.kind_dirname, 'yourname', vim.fs.basename(ctx.dest_path)))
         end
         return paths
      end,
   },
}
```

`<project_root>/.mql-compile.lua`:
```lua
return {
   send = { enabled = true },
}
```

Then, compiling `<project_root>/mt5/myea.mq5` (an EA) sends `myea.ex5` to:
- `~/VPS/shared/MQL5/Experts/yourname/myea.ex5`
- `~/Applications/MT5.app/.../MQL5/Experts/yourname/myea.ex5`

The sending runs after renaming, and before `hooks.post`.

## Hooks

Run your own functions before / after compiling.

| Hook   | Timing                                         | ctx                     | Return           |
| ------ | ---------------------------------------------- | ----------------------- | ---------------- |
| `pre`  | Before compiling                               | `mql_compile.Ctx`       | `false` to abort |
| `post` | After compiling (and renaming), even if failed | `mql_compile.ResultCtx` | (ignored)        |

```lua
opts = {
   hooks = {
      ---@param ctx mql_compile.Ctx
      pre = function(ctx)
         if ctx.ver == nil then
            vim.notify('No version found. Abort.')
            return false -- Abort compiling
         end
      end,
      ---@param ctx mql_compile.ResultCtx
      post = function(ctx)
         if ctx.ok then vim.notify('Compiled: ' .. ctx.dest_path) end
      end,
   },
},
```

Errors in hooks are caught and notified. (An error in `pre` also aborts compiling.)

## Ctx

The `ctx` table passed to user functions (`rename.to`, `send.to`, `hooks.*`).

```lua
---@class mql_compile.Ctx
---@field root string      Abs path of project root
---@field project string   Project name (= basename of root, e.g. 'myproject')
---@field ft string        Filetype ('mql5' | 'mql4')
---@field src_path string  Source file path (relative to cwd)
---@field dir string       Parent dir of the source file
---@field base string      Basename with source ext (e.g. 'myea.mq5')
---@field fname string     Filename without ext (e.g. 'myea')
---@field ext string       Compiled ext (e.g. 'ex5')
---@field ext_src string   Source ext (e.g. 'mq5')
---@field ver string?      '#property version' value (e.g. '1.10' or nil)
---@field major string?    Major version (e.g. '1')
---@field minor string?    Minor version (e.g. '10')
---@field kind 'expert'|'indicator'|'script'|'library'|'service'|nil  Detected from the source (e.g. '#property indicator_*', 'OnTick()')
---@field kind_dirname 'Experts'|'Indicators'|'Scripts'|'Libraries'|'Services'|nil  MQL directory name for the kind (e.g. 'Experts')
---@field dest_path string? Abs path of the compiled file finally placed (Not set in `rename.to`)

---@class mql_compile.ResultCtx : mql_compile.Ctx
---@field dest_path string Abs path of the compiled file finally placed
---@field ok boolean       true if no errors
---@field counts table     Counts of each quickfix type (e.g. { error = 1, warning = 2 })
```

`kind` (MQL program type) is detected from the source file (not from included files):

| kind        | Detected by                                |
| ----------- | ------------------------------------------ |
| `library`   | `#property library`                        |
| `service`   | `#property service`                        |
| `indicator` | `#property indicator_*` or `OnCalculate()` |
| `script`    | `#property script_*`, or `OnStart()` only  |
| `expert`    | `OnTick()`                                 |

> [!Note]
> `mql_compile.RenameCtx` is deprecated. Use `mql_compile.Ctx` instead.

## Usage

### Compiling

User Commands:
```vim
" Compile the selected source file with ui.select
:MQLCompile
" Compile the specific source file
:MQLCompile my_ea.mq5
" Compile current file
:MQLCompile %
```
Lua API functions:
```lua
-- Compile the selected source file with ui.select
require('mql_compile').compile()
-- Compile the specific source file
require('mql_compile').compile('my_ea.mq5')
-- Compile current file
require('mql_compile').compile('%')
```
- This plugin finds mql5/mql4 source files by patterns given in `opts.ft.*.pattern`, from project root.  
- Symbolic links are excluded.


### Show options

Show all current options as table. Just for checking.
```vim
:MQLCompileShowOptions
```

## Keymaps

Sample:
```lua
keys = {
    { '<F7>', '<cmd>MQLCompile<cr>' },
},
```
or
```lua
keys = {
    { '<F7>', function() require('mql_compile').compile() end },
},
```

## Highlights

> [!Warning]
> This is still an experimental feature.
> The highlights seems not to be modified by this plugin.
> Highly recommend using other plugins for highlighting or beautifing qflist.

Set-up highlight groups in quickfix list.  

To use default, leave `hl_groups = nil`.
```lua
opts = {
   highlights = { -- Highlights on quickfix window
      enabled = true,
      hl_prefix = 'qf',
      hl_groups = {
         filename = { 'FileName', { link = 'Directory' } },  -- { '<Highlight name>' , { <highlight options> } }
         separator_left = { 'SeparatorLeft', { fg = '#cccccc' } },
         separator_right = { 'SeparatorRight', { fg = '#cccccc' } },
         line_nr = { 'LineNr', { fg = '#888888' } },
         col = { 'Col', { link = 'DiagnosticError' } },
         error = { 'Error', { link = 'DiagnosticError' } },
         warning = { 'Warning', { link = 'DiagnosticWarn' } },
         info = { 'Info', { link = 'DiagnosticInfo' } },
         hint = { 'Hint', { link = 'DiagnosticHint' } },
         note = { 'Note', { link = 'DiagnosticHint' } },
         code = { 'Code', { fg = '#888888' } },
         text = { 'Text', { link = 'Normal' } },
      },
   },
},
```

## Project Specific Options

To override global options for a specific project, add `.mql-compile.lua` to the project root, following the [Default options](#default-options) structure.
It is reloaded from the source file's project root on each compile, so you can switch between projects in a single nvim session.

`<project_root>/.mql-compile.lua`:
```lua
return {
   rename = {
     enabled = false, -- ex.) Disable renaming in this project
   },
   -- Add your project-specific config here
}
```

## notify

This plugin optionally uses `vim.notify()` to show messages to users.  
For those who want to have nicer messages, follow this.

1. Install [nvim-notify](https://github.com/rcarriga/nvim-notify)
2. Put below code to replace default notify.

```lua
-- ex.) with lazy.nvim
return {
   'rcarriga/nvim-notify',
   config = function()
      vim.notify = require('notify')
   end,
}
```
Then `mql-compile` shows messages through it.


## Test codes to compile

There are some test mql5 codes in: `test/*.mq5`
- ok.mq5
- info.mq5
- warn.mq5
- err.mq5

Try to compile them for test.

Or use `test/test.lua` to generate temporary buffer with diagnostics.

## Issues

### Inaccurate error displaying

> [!Warning]
> The metaeditor returns errors that do not make sense, so often.

For example,

If you forget to add ';' at the end of class:
```cpp
class ClassA {
} // line A: forgot to add ';'

class ClassB { // line B: `class 'name' expected` error occurs
};
```

The error is actually occurring on line A.  
But the MetaEditor says that line B has a different error (completely different).  
This confuses and annoys us.  
Especially, if you split files & use `#include`, it becomes quite difficult to find the cause.

Unfortunately, these are the weak point of metaeditor's linting, I guess.


## Additional Informations

### Highlight with treesitter

See [notes/highlight_with_treesitter.md]()

### LSP

See [notes/lsp.md](notes/lsp.md)

### Format

See [notes/format.md](notes/format.md)

### Investigation Note

Researched and verified detailed data of wine and `metaeditor.exe` / `MetaEditor64.exe` commands.  
See [notes/wine_and_metaeditor.md](notes/wine_and_metaeditor.md).

Path specifications and path conversions are investigated.

## Recommendation

[https://github.com/stevearc/overseer.nvim](overseer.nvim) may be the better choice.


## AI support

This project was hand-written by the maintainer up to v0.6.x, and has been heavily supported by AI coding assistance (Claude Code) since v0.7.0.


## License

[MIT License](./LICENSE)

