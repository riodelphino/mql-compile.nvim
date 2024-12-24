local M = {}

local _ = require('mql_compiler')
local fn = require('mql_compiler.functions')

function M.do_compile(metaeditor_path, source_path, log_path)
   local msg = ''
   -- Compile
   local compile_cmd = string.format('wine "%s" /compile:"%s" /log:"%s"', metaeditor_path, source_path, log_path)
   local compile_result = vim.fn.system(compile_cmd)

   -- Check result
   local source_filename = source_path:match("([^/\\]+)$")
   if vim.v.shell_error == 0 then
      msg = "Finished compile '" .. source_filename .. "'.\rLog: " .. log_path
      fn.notify(msg, vim.log.levels.INFO)
   elseif vim.v.shell_error == 1 then
      msg = "Finished compile '" .. source_filename .. "' with warnings.\rLog: " .. log_path
      fn.notify(msg, vim.log.levels.INFO)
   elseif vim.v.shell_error == 2 then
      msg = "Failed compile '" .. source_filename .. "' with errors.\rLog: " .. log_path
      fn.notify(msg, vim.log.levels.ERROR)
      return
   end
end

function M.compile(source_path)
   local msg = ''
   -- ex.) compile_mql('/path/to/your/file.mq5')

   source_path, _._mql = fn.get_source(source_path)

   local mql = _._mql
   local opts = _._opts
   local os_type = _._os_type

   msg = "Compiling '" .. source_path .. "'"
   fn.notify(msg, vim.log.levels.INFO)


   -- Set paths
   local metaeditor_path = vim.fn.expand(mql.metaeditor_path)
   local log_path = source_path:gsub('%.' .. mql.extension .. '$', '.' .. opts.log.extension)
   log_path = fn.convert_path_to_os(log_path, mql.wine_drive_letter, os_type)
   local qf_path = log_path:gsub('%.log$', '.' .. opts.quickfix.extension)

   -- Compile
   M.compile(metaeditor_path, source_path, log_path)

   -- Convert encoding for mac
   if (os_type == 'macos') then
      fn.convert_encoding(log_path)
   end

   -- Convert log to quickfix format
   fn.log_to_qf(log_path, qf_path)

   -- Open quickfix
   vim.cmd('cfile ' .. qf_path)
   vim.cmd('copen')
end


return M
