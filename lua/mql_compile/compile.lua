local M = {}

local opt = require('mql_compile.options')
local fn = require('mql_compile.functions')

function M.async_compile(metaeditor_path, source_path, log_path)
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
      cmd = metaeditor_path -- "" is not needed somewhy
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
         -- notify: compile.on_started
         if opts.notify.compile.on_started then
            msg = "Compiling: '" .. source_path .. "'"
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
            -- notify: log.on_saved
            if opts.notify.log.on_saved then
               if fn.file_exists(log_path) then
                  msg = "Saved log: '" .. log_path .. "'"
                  fn.notify(msg, vim.log.levels.INFO)
               end
            end

            -- Convert encoding for mac
            local os_type = opt._os_type
            if os_type == 'macos' then fn.convert_encoding(log_path) end

            -- Convert log to information format
            local info_cnt = fn.generate_info(log_path, opts.information.actions)

            -- Convert log to quickfix format
            local qf_cnt = fn.generate_qf(log_path, opts.quickfix.keywords)

            -- NOT WORKS: How to get shell error ?
            -- if compile_shell_error == 1 then
            --    msg = 'Error on compiling: ' .. source_path
            --    vim.notify(msg, vim.log.levels.ERROR)
            --    return
            -- end

            -- Set level
            local level
            if qf_cnt.error ~= nil then
               level = vim.log.levels.ERROR
            elseif qf_cnt.warning ~= nil then
               level = vim.log.levels.WARN
            else
               level = vim.log.levels.INFO
            end

            -- Check result & notify
            local source_filename = fn.get_relative_path(source_path)

            -- notify: compile.on_finished
            if opts.notify.compile.on_finished then
               local msg_main
               local msg_qf
               if opts.notify.quickfix.on_finished then
                  msg_qf = fn.format_table_to_string(qf_cnt, opts.quickfix.keywords)
               else
                  msg_qf = ''
               end
               if qf_cnt.error ~= nil then
                  -- Failed
                  msg_main = "Failed compiling: '" .. source_filename .. "'"
                  fn.notify(msg_main .. '\n' .. msg_qf, level)
               else
                  -- Succeeded
                  msg_main = "Succeeded compiling: '" .. source_filename .. "'"
                  fn.notify(msg_main .. '\n' .. msg_qf, level)
               end
            end

            -- Open quickfix
            if opts.quickfix.auto_open.enabled then
               local open_flag = false
               for _, key in ipairs(opts.quickfix.auto_open.open_with) do
                  if qf_cnt[key] ~= nil then open_flag = true end
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

   -- Adjust metaeditor's path
   local metaeditor_path = fn.get_absolute_path(mql.metaeditor_path)

   -- Check exe exists
   if not fn.file_exists(metaeditor_path) then
      local msg = 'Command does not exist: "' .. metaeditor_path .. '"'
      fn.notify(msg, vim.log.levels.ERROR)
      return
   end

   -- Generate log path
   local basename = fn.get_basename(source_path)
   local log_path = basename .. '.' .. opts.log.extension

   -- Adjust source_path
   source_path = fn.get_relative_path(source_path) -- To avoid wrongly converting from '/Users/yourname' to 'Users/yourname' in mql's include

   -- Execute async-compiling
   local compile_shell_error = M.async_compile(metaeditor_path, source_path, log_path)
   return compile_shell_error
end

return M
