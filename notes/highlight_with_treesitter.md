# Highlight with treesitter

There is a parser [tree-sitter-mql5](https://github.com/mskelton/tree-sitter-mql5) which extends `tree-sitter-cpp`.  
But it's incomplete and not works.

Just use `cpp` parser instead. That's enough.


Leave the incomplete steps for record below.

## Incomplete steps for tree-sitter-mql5

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

May need large modification in `tree-sitter-mql5`.
