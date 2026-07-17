local M = {}

local fn = require('mql_compile.functions')
local opt = require('mql_compile.options')
local cmp = require('mql_compile.compile')

function M.create_commands()
   -- :MQLCompile <source_path>
   vim.api.nvim_create_user_command('MQLCompile', function(opts)
      local source_path = opts.fargs[1]
      if source_path then
         cmp.compile(source_path)
         return
      end

      local root = fn.get_root()
      local files = fn.find_source_files(root, { '*.mq5', '*.mq4' }) -- abspath

      if next(files) == nil then
         local msg = 'Not found any source files in: ' .. root
         fn.notify(msg, vim.log.levels.ERROR)
         return
      end

      -- key: relpath (for displaying in ui.select)
      -- { 'mt5/myea.mq5' = { abspath = '/path/to/mt5/myea.mq5' } }
      local sources = {}
      for _, abspath in ipairs(files) do
         local relpath = vim.fs.relpath(root, abspath)
         sources[relpath] = {
            abspath = abspath,
         }
      end

      vim.ui.select(vim.fn.keys(sources), { title = 'Select source file:' }, function(choice)
         if not choice then return end
         local source = sources[choice]
         cmp.compile(source.abspath)
      end)
   end, { nargs = '?' })

   -- :MQLCompilePrintOptions
   vim.api.nvim_create_user_command('MQLCompileShowOptions', function()
      fn.notify(vim.inspect(opt._opts))
   end, { nargs = 0 })
end

return M
