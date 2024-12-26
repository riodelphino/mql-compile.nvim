local M = {}

local opt = require('mql_compile.options')
local fn = require('mql_compile.functions')

function M.do_compile(metaeditor_path, source_path, log_path)
   local opts = opt.get_opts()
   local msg = ''
   local compile_cmd = ''
   -- Compile
   if (opts.wine.enabled) then
      compile_cmd = string.format('%s "%s" /compile:"%s" /log:"%s"', opts.wine.command, metaeditor_path, source_path, log_path)
   else
      compile_cmd = string.format('%s /compile:"%s" /log:"%s"', metaeditor_path, source_path, log_path)
   end

   if (opts.notify.compile.on_start) then
      msg = "Compiling '" .. source_path .. "' ..."
      fn.notify(msg, vim.log.levels.INFO)
   end

   local result = vim.fn.system(compile_cmd)
   local compile_shell_error = vim.v.shell_error

   -- notify
   if (opts.notify.log.on_saved) then
      msg = "Saved log: '" .. log_path .. "'"
      fn.notify(msg, vim.log.levels.INFO)
   end

   return compile_shell_error -- 0: failed / 1: succeeded
end

function M.compile(source_path)
   local opts = opt.get_opts()
   local msg = ''
   local mql

   source_path, mql = fn.get_source(source_path)

   opt._mql = mql
   local os_type = opt._os_type

   -- Set paths
   local metaeditor_path = vim.fn.expand(mql.metaeditor_path)
   local log_path = source_path:gsub('%.' .. mql.extension .. '$', '.' .. opts.log.extension)
   log_path = fn.convert_path_to_os(log_path, mql.wine_drive_letter, os_type)
   local qf_path = log_path:gsub('%.log$', '.' .. opts.quickfix.extension)
   local info_path = log_path:gsub('%.log$', '.' .. opts.information.extension)

   -- Do compile
   -- local compile_shell_error = M.do_compile(metaeditor_path, source_path, log_path)
   M.do_compile(metaeditor_path, source_path, log_path)

   -- Convert encoding for mac
   if (os_type == 'macos') then
      fn.convert_encoding(log_path)
   end

   -- Convert log to quickfix format
   local log_cnt = fn.log_to_qf(log_path, qf_path, opts.quickfix.keywords)

   -- Convert log to information format
   local info_cnt = fn.log_to_info(log_path, info_path, opts.information.keywords)

   -- check log count & set base level
   local level
   if (log_cnt.error > 0) then
      level = vim.log.levels.ERROR
   elseif (log_cnt.warning > 0) then
      level = vim.log.levels.WARN
   else
      level = vim.log.levels.INFO
   end

   -- notify 'log.counts'
   if (opts.notify.log.counts) then
      msg = fn.get_count_msg(log_cnt)
      fn.notify(msg, level)
   end

   -- notify 'information.counts'
   if (opts.notify.information.counts) then
      msg = fn.get_count_msg(info_cnt)
      fn.notify(msg, vim.log.levels.INFO)
   end

   -- Check result & notify
   local source_filename = source_path:match("([^/\\]+)$")

   if log_cnt.error > 0 then
      if (opts.notify.compile.on_failed) then
         msg = "Failed compiling '" .. source_filename .. "'"
         fn.notify(msg, level)
      end
   else
      if (opts.notify.compile.on_succeeded) then
         msg = "Succeeded compiling '" .. source_filename .. "'"
         fn.notify(msg, level)
      end
   end


   -- Open quickfix
   vim.cmd('cfile ' .. qf_path)
   if (opts.quickfix.auto_open.enabled) then
      local open_flag = false
      for _, key in ipairs(opts.quickfix.auto_open.open_with) do
         if (log_cnt[key] ~= nil and log_cnt[key] > 0) then
            open_flag = true
         end
      end
      if (open_flag) then
         vim.cmd('copen')
      end
   end

   -- Delete log
   if (opts.log.delete_after_load) then
      vim.fn.delete(log_path)
      -- notify
      if (opts.notify.log.on_deleted) then
         msg = "Deleted log: '" .. log_path .. "'"
         fn.notify(msg, vim.log.levels.INFO)
      end
   end

   -- Delete info
   if (opts.information.delete_after_load) then
      vim.fn.delete(info_path)
      -- notify
      if (opts.notify.infomation.on_deleted) then
         msg = "Deleted info: '" .. info_path .. "'"
         fn.notify(msg, vim.log.levels.INFO)
      end
   end

   -- o notify
   -- Delete quickfix
   if (opts.quickfix.delete_after_load) then
      vim.fn.delete(qf_path)
      -- notify
      if (opts.notify.quickfix.on_deleted) then
         msg = "Deleted quickfix: '" .. qf_path .. "'"
         fn.notify(msg, vim.log.levels.INFO)
      end
   end
end


return M
