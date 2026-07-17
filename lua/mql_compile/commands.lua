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
      else
         local root = fn.get_root()
         -- Get source files
         local files = fn.find_source_files(root, { '*.mq5', '*.mq4' })
         if next(files) == nil then
            local msg = 'Not found any source files in: ' .. root
            fn.notify(msg, vim.log.levels.ERROR)
            return
         end
         -- Get relative paths
         local rel_files = {}
         for i, file in ipairs(files) do
            rel_files[i] = vim.fs.relpath(root, file)
         end
         -- Show ui.select to choose source file
         vim.ui.select(rel_files, { title = 'Select source file:' }, function(path)
            local abspath = vim.fs.joinpath(root, path)
            cmp.compile(abspath)
         end)
      end
   end, { nargs = '?' })

   -- :MQLCompilePrintOptions
   vim.api.nvim_create_user_command('MQLCompileShowOptions', function()
      fn.notify(vim.inspect(opt._opts))
   end, { nargs = 0 })
end

return M
