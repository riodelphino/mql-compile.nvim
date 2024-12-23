# mql-compiler.nvim

A Neovim plugin for compiling MQL5 scripts.  
Without heavy MetaEditor GUI (Compiles on command-line).

> [!Caution]
> Still testing. Be careful to use, not to lose your files.

> [!Caution]
> Currently works only in 'macOS + wine + wineskin + MT5' environment.


## Functions
- Compile MQL5
- Show errors in quickfix (& jump to the position)

## Requirement
    - MT5 installed (on wine)

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use 'riodelphino/mql-compiler.nvim'
```

Using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
    'riodelphino/mql-compiler.nvim',
    opts = {
       metaeditor_path = '~/Applications/Wineskin/MT5.app/drive_c/Program Files/MT5/MetaEditor64.exe',
       include_path = '',
       wine_drive_letter = 'Z',
       timeout = 5000, -- msec
    },
    keys = {
        {'<leader>mc', 'require("mql_compiler").compile_mql5()'},
    },
}
```

## Usage

Still working with this ...
```
:lua require('mql_compiler').compile_mql5("MyEA.mq5")
```

## TO-DO

> [!Important]
> Need quick add

- [ ] Options (MT5's path, Include path, enable quickfix, wine's drive letter)
- [ ] Require fugitive
- [ ] '%' or 'no arg' also can compile current mql5 file
- [ ] Detect git root
- [ ] List up & select from git root's mql5 files 
- [ ] If only one mql5 on git root, compile without prompt
- [ ] Remove ^M from quickfix (encoding problem)
- [ ] Show fugitive message on progress & success or error
- [ ] Adoopt to MT5 on Windows
- [x] Convert given macOS's path to Windows path

> [!Note]
> Hope to add in future

- [ ] MQL4 compiling

