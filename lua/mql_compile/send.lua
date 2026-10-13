local M = {}

local fn = require('mql_compile.functions')

-- Send (copy or move) the compiled file to the paths returned from `send.to`
---@param opts table
---@param ctx mql_compile.ResultCtx
function M.send(opts, ctx)
   ctx.sent_paths = {}
   if not opts.send.enabled or not ctx.ok then return end

   local mode = opts.send.mode
   if mode ~= 'copy' and mode ~= 'move' then
      fn.notify("Failed to send\nInvalid `send.mode`: '" .. tostring(mode) .. "' (Use 'copy' | 'move')", vim.log.levels.ERROR)
      return
   end

   if not fn.file_exists(ctx.dest_path) then
      fn.notify("Failed to send\nNot found compiled file: '" .. ctx.dest_path .. "'", vim.log.levels.ERROR)
      return
   end

   local ok, paths = pcall(opts.send.to, ctx)
   if not ok then
      fn.notify('Error in `send.to`:\n' .. tostring(paths), vim.log.levels.ERROR)
      return
   end
   if paths == nil then return end -- nil: Send nothing
   if type(paths) == 'string' then paths = { paths } end

   local sent = {}
   local failed = false
   local keep_source = false -- true if the source itself is one of the destinations
   for _, path in ipairs(paths) do
      path = vim.fs.normalize(vim.fn.fnamemodify(vim.fs.normalize(path), ':p')) -- Expand '~' & make absolute
      if path == ctx.dest_path then
         keep_source = true -- Already there. (Never copy onto itself, nor remove it on 'move')
         table.insert(sent, path)
      else
         local dir = vim.fs.dirname(path)
         -- mkdir
         if not fn.folder_exists(dir) then
            if pcall(vim.fn.mkdir, dir, 'p') then
               if opts.notify.send.on_mkdir then fn.notify("Created dir: '" .. dir .. "'", vim.log.levels.INFO) end
            end
         end
         -- copy (fails here if mkdir failed)
         local copied, err = vim.uv.fs_copyfile(ctx.dest_path, path)
         if copied then
            table.insert(sent, path)
         else
            failed = true
            fn.notify("Failed to send to: '" .. path .. "'\n" .. tostring(err), vim.log.levels.ERROR)
         end
      end
   end
   ctx.sent_paths = sent

   -- move: Remove the source only if all copies succeeded
   local moved = false
   if mode == 'move' and #sent > 0 and not keep_source then
      if failed then
         fn.notify("Kept the compiled file (some sending failed): '" .. ctx.dest_path .. "'", vim.log.levels.WARN)
      else
         local removed, err = vim.uv.fs_unlink(ctx.dest_path)
         if removed then
            moved = true
         else
            fn.notify("Failed to remove the compiled file: '" .. ctx.dest_path .. "'\n" .. tostring(err), vim.log.levels.ERROR)
         end
      end
   end

   if opts.notify.send.on_sent and #sent > 0 then
      local title = moved and 'Moved to:' or 'Sent to:'
      fn.notify(title .. "\n'" .. table.concat(sent, "'\n'") .. "'", vim.log.levels.INFO)
   end
end

return M
