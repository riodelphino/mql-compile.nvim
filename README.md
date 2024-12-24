# mql-compiler.nvim

A Neovim plugin for compiling MQL5 scripts.  
Without heavy MetaEditor GUI (Compiles on command-line).

> [!Caution]
> Still testing. Be careful to use, not to lose your files.

> [!Caution]
> Currently works only in 'macOS + wine(wineskin) + MT5' environment.


## Features
**Main features**
- Compile MQL5
- Show errors in quickfix (& jump to the position)
- Auto detect mql5/mql4 by given source path
- Works on MacOS + wine

**In future**
- Compile MQL4 (in future)
- Works on Windows (in future)


## Requirement
- MT5 installed (on wine)

## Installation

Using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
   'riodelphino/mql-compiler.nvim',
   lazy = false,
   -- ft = { 'cpp', 'c' }, -- Not recommend
   opts = {
      default = 'mql5', -- 'mql5' | 'mql4'
      quickfix = {
         alert_keys = { 'error', 'warning' }, -- Alert keywords showen in quickfix
         extension = 'qfix',
      },
      log = {
         extension = 'log',
      },
      mql5 = {
         metaeditor_path = '~/Applications/Wineskin/MT5.app/drive_c/Program Files/MetaTrader 5/MetaEditor64.exe', -- your MT5 exe's path
         include_path = '',
         source_path = '',
         extention = 'mq5',
         wine_drive_letter = 'Z:',
         timeout = 5000,
      },
      mql4 = {
         metaeditor_path = '~/Applications/Wineskin/MT4.app/drive_c/Program Files (x86)/XMTrading MT4/metaeditor.exe', -- your MT4 exe's path
         include_path = '',
         source_path = '',
         extention = 'mq4',
         wine_drive_letter = 'Z:',
         timeout = 5000,
      },
   },
   keys = {
       {'<F7>', '<cmd>MQLCompiler<cr>'},
   },
   cmd = {
      { 'MQLCompiler', 'MQLCompilerSetSource', },
   },
}
```

## 'metaeditor_path' sample

Default path for MetaEditor64.exe(MT5) or metaeditor.exe(MT4).  
(It depends on your settings.)
```lua
{
   opts = {
      mql5 = {
          -- MacOS (via wine)
          -- 'MT5.app' is the name of app you set on wineskin.
          metaeditor_path = '~/Applications/Wineskin/MT5.app/drive_c/Program Files/MetaTrader 5/MetaEditor64.exe',

          -- Windows (maybe NOT WORKS NOW, just a note)
          metaeditor_path = 'C:/Program Files/MetaTrader 5/MetaEditor64.exe',
      },
      mql4 = {
          -- MacOS (via wine)
          -- 'MT4.app' is the name of app you set on wineskin.
          metaeditor_path = '~/Applications/Wineskin/MT5.app/drive_c/Program Files (x86)/MetaTrader 4/metaeditor.exe',
          -- Windows (maybe NOT WORKS NOW, just a note)
          metaeditor_path = 'C:/Program Files (x86)/MetaTrader 4/metaeditor.exe',
      }
   }
}

```


## Commands

This plugin auto-detects mql5/mql4 by extension given in source path.
```vim
" Set mql5 path
:MQLCompilerSetSource MyEA.mq5
" Compile it
:MQLCompiler
```
or
```vim
" Compile with path
:MQLCompiler MyEA.mq5
```
## Lua functions

Below lua functions also available. (with auto-detection by the extension)
```vim
:lua require('mql_compiler').set_source_path("MyEA.mq5")
:lua require('mql_compiler').compile_mql()
```
or
```vim
:lua require('mql_compiler').compile_mql("MyEA.mq5")
```

## TO-DO

> [!Important]
> Need quick add

- [ ] nvim freezes for seconds, until finishing compile
- [ ] Show just 'Result: errors x, warnings x (...)' message, remove others.
- [ ] Require fugitive
- [ ] Detect git root
- [ ] List up & select from git root's mql5 files 
- [ ] If only one mql5 on git root, compile without prompt
- [ ] Show fugitive message on progress & success or error
- [ ] Adoopt to MT5 on Windows
- [ ] Organize & split codes to functions
- [x] Convert given macOS's path to Windows path
- [x] Options (MT5's path, Include path, enable quickfix, wine's drive letter)
- [x] '%' or 'no arg' also can compile current mql5 file
- [x] Remove ^M from quickfix (encoding problem)

> [!Note]
> Hope to add in future

- [ ] MQL4 compiling

