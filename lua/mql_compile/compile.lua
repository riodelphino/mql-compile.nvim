local M = {}

local opt = require('mql_compile.options')
local fn = require('mql_compile.functions')

function M.async_compile(metaeditor_path, source_path, log_path, qf_path, info_path)
   local opts = opt.get_opts()
   local msg = ''

   local Job = require('plenary.job')

   -- metaeditor_path = '/Users/rio/Applications/Wineskin/MT5.app/drive_c/Program Files/MT5/MetaEditor64.exe'
   -- source_path = 'myea/ea_warnings.mq5'
   -- log_path = 'myea/ea_warnings.log'
   -- local cwd = '/Users/rio/Projects/git/FX/EA'
   local cwd = fn.get_dir(source_path)

   local cmd
   local args = {}
   if opts.wine.enabled then
      cmd = opts.wine.command
      args = { metaeditor_path, '/compile:' .. source_path, '/log:' .. log_path, '&>/dev/null' } -- '&>/dev/null' cannot avoid useless echo
   else
      cmd = metaeditor_path -- FIXME: "" is not needed ?
      args = { '/compile:' .. source_path, '/log:' .. log_path, '&>/dev/null' }
   end

   -- plenary.job for realtime operation
   ---@diagnostic disable-next-line: missing-fields
   Job:new({
      command = cmd,
      args = args,
      cwd = cwd,
      -- Below disabling strout x 4 not work...
      -- on_stdout = function() end,
      -- on_stderr = function() end,
      -- stdout_results = false,
      -- stderr_results = false,
      on_start = function()
         -- notify: compile.on_start
         if opts.notify.compile.on_start then
            msg = "Compiling '" .. source_path .. "' ..."
            fn.notify(msg, vim.log.levels.INFO)
         end
      end,
      on_exit = function(_, _) -- j, result
         -- This result value is incorrect at all in case of using 'wine'.
         -- if result == 0 then
         --    fn.notify('Succeeded compiling: ' .. source_path, vim.log.levels.INFO)
         -- else
         --    fn.notify('Failed compiling: (' .. return_val .. ')\n' .. 'stderr:\n' .. table.concat(j:stderr_result(), '\n'), vim.log.levels.ERROR)
         -- end

         -- Convert log encoding & convert to qf, info
         vim.schedule(function()
            local log_cnt
            local info_cnt

            -- notify: log.on_saved
            if opts.notify.log.on_saved then
               msg = "Saved log: '" .. log_path .. "'"
               fn.notify(msg, vim.log.levels.INFO)
            end

            -- Convert encoding for mac
            local os_type = opt._os_type
            if os_type == 'macos' then fn.convert_encoding(log_path) end

            -- Convert log to quickfix format
            log_cnt = fn.log_to_qf(log_path, qf_path, opts.quickfix.keywords)

            -- Convert log to information format
            info_cnt = fn.log_to_info(log_path, info_path, opts.information.actions)

            -- check log count & set base level
            if log_cnt == nil then
               msg = 'Error on loading log file: ' .. log_path
               fn.notify(msg, vim.log.levels.ERROR)
               return
            end
            if info_cnt == nil then
               msg = 'Error on loading log file: ' .. log_path
               fn.notify(msg, vim.log.levels.ERROR)
               return
            end
            -- NOT WORKS: How to get shell error ?
            -- if compile_shell_error == 1 then
            --    msg = 'Error on compiling: ' .. source_path
            --    vim.notify(msg, vim.log.levels.ERROR)
            --    return
            -- end
            local level
            if log_cnt.error > 0 then
               level = vim.log.levels.ERROR
            elseif log_cnt.warning > 0 then
               level = vim.log.levels.WARN
            else
               level = vim.log.levels.INFO
            end

            -- notify: log.on_count
            if opts.notify.log.on_count then
               msg = fn.table_to_string(log_cnt, opts.quickfix.keywords)
               fn.notify(msg, level)
            end

            -- notify: information.on_count
            if opts.notify.information.on_count then
               msg = fn.table_to_string(info_cnt, opts.information.actions)
               fn.notify(msg, vim.log.levels.INFO)
            end

            -- Check result & notify
            local source_filename = fn.get_relative_path(source_path)

            if log_cnt.error > 0 then
               -- notify: compile.on_failed
               if opts.notify.compile.on_failed then
                  msg = "Failed compiling '" .. source_filename .. "'"
                  fn.notify(msg, level)
               end
            else
               -- notify: compile.on_succeeded
               if opts.notify.compile.on_succeeded then
                  msg = "Succeeded compiling '" .. source_filename .. "'"
                  fn.notify(msg, level)
               end
            end

            -- Open quickfix
            vim.cmd('cfile ' .. qf_path)
            if opts.quickfix.auto_open.enabled then
               local open_flag = false
               for _, key in ipairs(opts.quickfix.auto_open.open_with) do
                  if log_cnt[key] ~= nil and log_cnt[key] > 0 then open_flag = true end
               end
               if open_flag then vim.cmd('copen') end
            end

            -- Delete log
            if opts.log.delete_after_load then
               vim.fn.delete(log_path)
               -- notify: log.on_deleted
               if opts.notify.log.on_deleted then
                  msg = "Deleted log: '" .. log_path .. "'"
                  fn.notify(msg, vim.log.levels.INFO)
               end
            end

            -- Delete quickfix
            if opts.quickfix.delete_after_load then
               vim.fn.delete(qf_path)
               -- notify: quickfix.on_deleted
               if opts.notify.quickfix.on_deleted then
                  msg = "Deleted quickfix: '" .. qf_path .. "'"
                  fn.notify(msg, vim.log.levels.INFO)
               end
            end

            -- Delete info
            if opts.information.delete_after_load then
               vim.fn.delete(info_path)
               -- notify: info.on_deleted
               if opts.notify.information.on_deleted then
                  msg = "Deleted info: '" .. info_path .. "'"
                  fn.notify(msg, vim.log.levels.INFO)
               end
            end
         end)
      end,
   }):start()
end

function M.compile(source_path)
   local opts = opt.get_opts()
   local mql

   source_path, mql = fn.get_source(source_path)
   if source_path == nil or mql == nil then
      local msg = 'Cannot find any target files.'
      vim.notify(msg, vim.log.levels.ERROR)
      return
   end

   opt._mql = mql

   -- Set paths
   -- local metaeditor_path = vim.fn.expand(mql.metaeditor_path)
   local metaeditor_path = fn.get_absolute_path(mql.metaeditor_path)
   -- local pattern = fn.pattern_bash_to_lua(mql.pattern) -- Convert pattern from '*.mq5' to '.*%.mq5'
   local basename = fn.get_basename(source_path)
   local log_path = basename .. '.' .. opts.log.extension
   local qf_path = basename .. '.' .. opts.quickfix.extension
   local info_path = basename .. '.' .. opts.information.extension

   -- Execute async-compiling
   source_path = fn.get_relative_path(source_path) -- To avoid wrongly converting from '/Users/yourname' to 'Users/yourname' in mql's include
   local compile_shell_error = M.async_compile(metaeditor_path, source_path, log_path, qf_path, info_path)
   return compile_shell_error
end

return M
