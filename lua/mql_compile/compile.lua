local M = {}

local opt = require('mql_compile.options')
local fn = require('mql_compile.functions')

function M.async_compile(metaeditor_path, source_path, log_path, compiled_path, target_path)
   local opts = opt.get_opts()
   local msg = ''
   local Job = require('plenary.job')
   local cwd = fn.get_root(source_path)
   local cmd
   local args = {}
   local dev_null = '&>/dev/null' -- Don't need this now
   if opts.compile.wine.enabled then
      cmd = opts.compile.wine.command
      args = { metaeditor_path, '/compile:' .. source_path, '/log:' .. log_path, dev_null }
   else
      cmd = metaeditor_path -- "" is not needed somewhy
      args = { '/compile:' .. source_path, '/log:' .. log_path, dev_null }
   end

   if opts.notify.debug.compile.show_cmd then
      msg = 'DEBUG: compiling command:\n' .. cmd .. ' ' .. table.concat(args, ' ')
      fn.notify(msg, vim.log.levels.INFO)
   end
   if opts.notify.debug.compile.show_cwd then
      msg = 'DEBUG: cwd:\n' .. cwd
      fn.notify(msg, vim.log.levels.INFO)
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
            msg = "Start compiling: '" .. source_path .. "'"
            fn.notify(msg, vim.log.levels.INFO)
         end
      end,
      on_exit = function(_, _) -- j, result
         -- This result value is incorrect at all in case of using 'wine'.
         -- if result == 0 then
         --    fn.notify('Succeeded compiling: ' .. source_path, vim.log.levels.INFO)
         -- else
         --    fn.notify('Failed to compile: (' .. return_val .. ')\n' .. 'stderr:\n' .. table.concat(j:stderr_result(), '\n'), vim.log.levels.ERROR)
         -- end

         -- Convert log encoding & convert to qf, info
         vim.schedule(function()
            -- notify: log.on_generated
            if opts.notify.log.on_generated then
               if fn.file_exists(log_path) then
                  msg = "Generated log: '" .. log_path .. "'"
                  fn.notify(msg, vim.log.levels.INFO)
               end
            end

            -- Convert encoding for mac
            local os_type = opt._os_type
            if os_type == 'macos' then fn.convert_encoding(log_path) end

            -- Convert log to information format
            local info_cnt = fn.generate_info(log_path, opts.information.actions)

            -- Convert log to quickfix format
            local qf_cnt = fn.generate_qf(log_path, opts.quickfix.types)

            -- NOT WORKS: How to get shell error ?
            -- if compile_shell_error == 1 then
            --    msg = 'Error on compiling: ' .. source_path
            --    vim.notify(msg, vim.log.levels.ERROR)
            --    return
            -- end

            -- Set level
            local level
            if qf_cnt.error ~= nil then
               level = opts.notify.levels.failed
            elseif qf_cnt.warning ~= nil then
               level = opts.notify.levels.succeeded.warn
            elseif qf_cnt.information ~= nil then
               level = opts.notify.levels.succeeded.info
            else
               level = opts.notify.levels.succeeded.none
            end

            -- Check result & notify
            local source_filename = fn.get_relative_path(source_path)

            -- notify: compile.on_finished
            if opts.notify.compile.on_finished then
               local msg_main
               local msg_qf_cnt
               if opts.notify.quickfix.on_finished then
                  msg_qf_cnt = fn.format_table_to_string(qf_cnt, opts.quickfix.types)
               else
                  msg_qf_cnt = ''
               end
               if qf_cnt.error ~= nil then
                  -- Failed
                  msg_main = "Failed to compile: '" .. source_filename .. "'"
                  fn.notify(msg_main .. '\n' .. msg_qf_cnt, level)
               else
                  -- Succeeded
                  msg_main = "Succeeded compiling: '" .. source_filename .. "'"
                  fn.notify(msg_main .. '\n' .. msg_qf_cnt, level)
               end
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

            -- Rename (mv compiled file to custom path)
            if qf_cnt.error == nil then
               local target_dir = fn.get_dir(target_path)
               -- mkdir
               if fn.folder_exists(target_dir) == false then
                  vim.fn.mkdir(target_dir)
                  if opts.notify.rename.on_mkdir then fn.notify("Created dir: '" .. target_dir .. "'", vim.log.levels.INFO) end
               end
               -- rename
               vim.fn.rename(compiled_path, target_path)
               if opts.notify.rename.on_renamed then fn.notify("Renamed to: '" .. target_path .. "'", vim.log.levels.INFO) end
            end

            -- Open quickfix
            if opts.quickfix.show.copen then
               -- Check Type matched in count
               local show_flag = false
               local types_to_show = opts.quickfix.show.with
               for _, type in ipairs(types_to_show) do
                  if qf_cnt[type] ~= nil then show_flag = true end
               end
               if show_flag then vim.cmd('copen') end
            end
         end)
      end,
   }):start()
end

function M.compile(source_path)
   local opts = opt.get_opts()
   local mql

   source_path, mql = fn.get_source(source_path, true)
   if source_path == nil or mql == nil then
      local msg = 'Cannot find any target files.'
      vim.notify(msg, vim.log.levels.ERROR)
      return
   end

   -- Adjust metaeditor's path
   local metaeditor_path = fn.get_absolute_path(mql.metaeditor_path)

   -- Check exe exists
   if not fn.file_exists(metaeditor_path) then
      local msg = 'Command does not exist: "' .. metaeditor_path .. '"'
      fn.notify(msg, vim.log.levels.ERROR)
      return
   end

   -- Generate log path
   local fname = fn.get_filename(source_path)
   local dir = fn.get_dir(source_path)
   local log_path = vim.fs.joinpath(dir, fname .. '.' .. opts.log.extension)
   log_path = fn.get_relative_path(log_path)

   -- Adjust source_path
   source_path = fn.get_relative_path(source_path) -- To avoid wrongly converting from '/Users/yourname' to 'Users/yourname' in mql's include

   -- Custom or default compiled path
   local target_path = M.get_target_path(source_path)
   if fn.file_exists(target_path) and not opts.compile.overwrite then
      fn.notify("Abort\nFile already exists: '" .. target_path .. "'", vim.log.levels.ERROR)
      return -- Abort
   end

   -- Compiled path
   local compiled_path = fn.get_compiled_path(source_path)

   -- Execute async-compiling
   local compile_shell_error = M.async_compile(metaeditor_path, source_path, log_path, compiled_path, target_path)
   return compile_shell_error
end

-- Custom or default target path
function M.get_target_path(source_path)
   local opts = opt.get_opts()
   local dir, base, fname, ext = fn.split_path(source_path)
   local target_ext = fn.get_compiled_extension(source_path)
   local default_target_path = fn.get_compiled_path(source_path)
   local target_path

   if opts.rename.enabled then
      local root = fn.get_root(source_path)
      local ver, major, minor = fn.get_version(source_path)
      target_path = opts.rename.get_custom_path(root, dir, base, fname, target_ext, ver, major, minor)
   else
      target_path = default_target_path
   end
   return target_path
end

return M
