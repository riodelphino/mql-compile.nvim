# Highlight with treesitter


## Configure parsers

Configure `cpp` parser for `mql5`, and `c` parser for `mql4`.  
There are two methods.

### 1. Setup with plugin

Use [mql-filetype.nvim](https://github.com/riodelphino/mql-filetype.nvim).  
Very easy. See and follow the plugin's [README](https://github.com/riodelphino/mql-filetype.nvim) instruction.


### 2. Setup manually

~/.config/nvim/ftplugin/mql5.lua:
```lua
vim.treesitter.start(bufnr, 'cpp')
```
~/.config/nvim/ftplugin/mql4.lua:
```lua
vim.treesitter.start(bufnr, 'c')
```
~/.config/nvim/init.lua:
```lua
vim.filetype.add({
   extension = {
      mq4 = 'mql4',
      mq5 = 'mql5',
      mqh = function(path, bufnr)
         local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ''
         if first_line:match('^%s*//%s*mql5') then     -- ex.) `// mql5`
            return 'mql5', function(b)
               vim.treesitter.start(b, 'cpp')          -- Use `cpp` TS parser
            end
         elseif first_line:match('^%s*//%s*mql4') then -- ex.) `// mql4`
            return 'mql4', function(b)
               vim.treesitter.start(b, 'c')            -- Use `c` TS parser
            end
         end
         -- fallback
         return 'mql5', function(b)
            vim.treesitter.start(b, 'cpp')
         end
      end,
   },
})
```
> [!Note]
> `vim.filetype.add()` detectors can return a second value — a callback that only fires when the filetype is actually applied, not on every query.


## Additional Informations

### mql5

There is a parser [tree-sitter-mql5](https://github.com/mskelton/tree-sitter-mql5) which extends `tree-sitter-cpp`.  
But it's incomplete and not works.

Just use `cpp` parser instead. That's good and enough.


#### Incomplete steps for tree-sitter-mql5

Leave the incomplete steps for further and future researching.

Add `mql5` custom parser to `nvim-treesitter`:
```lua
-- Add mql5 parser
local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
parser_config.mql5 = {
   install_info = {
      url = 'https://github.com/mskelton/tree-sitter-mql5', -- local path or git repo
      files = { 'src/parser.c', 'src/scanner.cc' }, -- note that some parsers also require src/scanner.c or src/scanner.cc
      -- optional entries:
      branch = 'main', -- default branch in case of git repo if different from master
      generate_requires_npm = true, -- if stand-alone parser without npm dependencies
      requires_generate_from_grammar = true, -- if folder contains pre-generated src/parser.c
   },
   filetype = 'mq5', -- if filetype does not match the parser name
}
-- Set filetypes for mql5
parser_configs.mql5.filetype = { 'mq5', 'mqh' } -- Adding `mqh` might cause a trouble with `mql-filetype.nvim` plugin
```

Then:
`:TSInstall mql5`

NOT WORKS.

Build `mql5.so` manually, but it also contains errors.

May need large modification in `tree-sitter-mql5`.


### mql4

In same reason with `mql5`, just using `c` parser for `mql4` is recommended.

