local M = {}

local fn = require('mql_compile.functions')
local opt = require('mql_compile.options')
local cmp = require('mql_compile.compile')

function M.create_commands()
   -- :MQLCompileSetSourc
   vim.api.nvim_create_user_command('MQLCompileSetSource', function(opts) fn.set_source_path(opts.args ~= '' and opts.args or nil) end, { nargs = '?' })

   -- :MQLCompile
   vim.api.nvim_create_user_command('MQLCompile', function(opts) cmp.compile(opts.args ~= '' and opts.args or nil) end, { nargs = '?' })

   -- :MQLCompilePrintOptions
   vim.api.nvim_create_user_command('MQLCompileShowOptions', function() fn.notify(vim.inspect(opt._opts)) end, { nargs = 0 })
end

return M
