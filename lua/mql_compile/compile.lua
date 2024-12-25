local M = {}

local opt = require('mql_compile.options')
local fn = require('mql_compile.functions')

function M.do_compile(metaeditor_path, source_path, log_path)
   local msg = ''
   local opts = opt._opts
   local compile_cmd = ''
   -- Compile
   if (opts.wine.enabled) then
      compile_cmd = string.format('%s "%s" /compile:"%s" /log:"%s"', opts.wine.command, metaeditor_path, source_path, log_path)
   else
      compile_cmd = string.format('%s /compile:"%s" /log:"%s"', metaeditor_path, source_path, log_path)
   end

   msg = "Compiling '" .. source_path .. "' ..."
   fn.notify(msg, vim.log.levels.INFO)

   local result = vim.fn.system(compile_cmd)

   -- Check result
   local source_filename = source_path:match("([^/\\]+)$")
   fn.notify('vim.v.shell_error: ' .. tostring(vim.v.shell_error), vim.log.levels.DEBUG)
   fn.notify('result: ' .. tostring(result), vim.log.levels.DEBUG)
   if vim.v.shell_error == 0 then
      msg = "Failed compiling '" .. source_filename .. "'"
      fn.notify(msg, vim.log.levels.ERROR)
   elseif vim.v.shell_error == 1 then
      msg = "Finish compiling '" .. source_filename .. "'"
      fn.notify(msg, vim.log.levels.INFO)
   end
end

function M.compile(source_path)
   local msg = ''
   local mql
   local opts = opt._opts

   source_path, mql = fn.get_source(source_path)

   opt._mql = mql
   local os_type = opt._os_type

   -- Set paths
   local metaeditor_path = vim.fn.expand(mql.metaeditor_path)
   local log_path = source_path:gsub('%.' .. mql.extension .. '$', '.' .. opts.log.extension)
   log_path = fn.convert_path_to_os(log_path, mql.wine_drive_letter, os_type)
   local qf_path = log_path:gsub('%.log$', '.' .. opts.quickfix.extension)

   -- Do compile
   M.do_compile(metaeditor_path, source_path, log_path)

   -- Convert encoding for mac
   if (os_type == 'macos') then
      fn.convert_encoding(log_path)
   end

   -- Convert log to quickfix format
   fn.log_to_qf(log_path, qf_path, opts.quickfix.keywords)

   -- Open quickfix
   vim.cmd('cfile ' .. qf_path)
   if (opts.quickfix.auto_open) then
      vim.cmd('copen')
   end

   -- Delete log
   if (opts.log.delete_after_load) then
      vim.fn.delete(log_path)
   else
      if (opts.notify.log.on_saved) then
         msg = "Saved log: '" .. log_path .. "'"
         fn.notify(msg, vim.log.levels.INFO)
      end
   end

   -- Delete quickfix
   if (opts.quickfix.delete_after_load) then
      vim.fn.delete(qf_path)
   else
      if (opts.notify.quickfix.on_saved) then
         msg = "Saved quickfix: '" .. qf_path .. "'"
         fn.notify(msg, vim.log.levels.INFO)
      end
   end
end


return M
