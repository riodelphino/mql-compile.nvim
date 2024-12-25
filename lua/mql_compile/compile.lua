local M = {}

local opt = require('mql_compile.options')
local fn = require('mql_compile.functions')

function M.do_compile(metaeditor_path, source_path, log_path)
   local msg = ''
   local opts = opt._oots
   local compile_cmd = ''
   -- Compile
   if (opts.wine.enabled) then
      compile_cmd = string.format('%s "%s" /compile:"%s" /log:"%s"', opts.wine.command, metaeditor_path, source_path, log_path)
   else
      compile_cmd = string.format('%s /compile:"%s" /log:"%s"', metaeditor_path, source_path, log_path)
   end

   local result = vim.fn.system(compile_cmd)

   -- Check result
   local source_filename = source_path:match("([^/\\]+)$")
   fn.notify('vim.v.shell_error: ' .. tostring(vim.v.shell_error), vim.log.levels.DEBUG)
   fn.notify('result: ' .. tostring(result), vim.log.levels.DEBUG)
   if vim.v.shell_error == 0 then
      msg = "Compiled '" .. source_filename .. "'.\nLog: " .. log_path
      fn.notify(msg, vim.log.levels.INFO)
   elseif vim.v.shell_error == 1 then
      msg = "Compiled '" .. source_filename .. "' with warnings.\nLog: " .. log_path
      fn.notify(msg, vim.log.levels.INFO)
   elseif vim.v.shell_error == 2 then
      msg = "Failed compile '" .. source_filename .. "' with errors.\nLog: " .. log_path
      fn.notify(msg, vim.log.levels.ERROR)
      return
   end
end

function M.compile(source_path)
   local msg = ''
   local mql
   -- ex.) compile_mql('/path/to/your/file.mq5')

   source_path, mql = fn.get_source(source_path)

   local opts = opt._opts
   opt._mql = mql
   local os_type = opt._os_type

   msg = "Compiling '" .. source_path .. "' ..."
   fn.notify(msg, vim.log.levels.INFO)


   -- Set paths
   local metaeditor_path = vim.fn.expand(mql.metaeditor_path)
   local log_path = source_path:gsub('%.' .. mql.extension .. '$', '.' .. opts.log.extension)
   log_path = fn.convert_path_to_os(log_path, mql.wine_drive_letter, os_type)
   local qf_path = log_path:gsub('%.log$', '.' .. opts.quickfix.extension)

   -- Compile
   M.do_compile(metaeditor_path, source_path, log_path)

   -- Convert encoding for mac
   if (os_type == 'macos') then
      fn.convert_encoding(log_path)
   end

   -- Convert log to quickfix format
   fn.log_to_qf(log_path, qf_path, opts.quickfix.alert_keys)

   -- Open quickfix
   vim.cmd('cfile ' .. qf_path)
   if (opts.quickfix.auto_open) then
      vim.cmd('copen')
   end
end


return M
