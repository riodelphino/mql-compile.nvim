# README

This is a test directory to know how this plugin works.

## Preparing

Ensure to add symbolic links to `MQL5` via following command:
```bash
cd test
ln -s MQL5 'path/to/MQL5'
```

ex.) with Sikarugir on macOS:
```bash
ln -s MQL5 '/Users/<username>/Applications/MetaTrader 5.app/Contents/SharedSupport/prefix/drive_c/Program Files/MetaTrade 5/MQL5'
```

## Usage

### Compiling Test
```vim
" Select source file and compile it
:MQLCompile
" Or specify the source file
:MQLCompile test/ok.mq5
:MQLCompile test/info.mq5
:MQLCompile test/warn.mq5
:MQLCompile test/err.mq5
```

### Check

Then, check followings:
- `notify` messages apear (depends on the config)
- `*.log` generation (the log path depends on the config)
- `quickfix` is displayed correctly (Exclude `ok.mq5`)
- `*.ex5` is generated (Execlude `err.mq5` / The saved path depends on the config)

### Show test buffer

A test lua code for generating/displaying a temporary buffer is available.
```vim
:lua dofile(vim.fs.joinpath(vim.fn.getcwd(), 'test/test.lua'))
```

