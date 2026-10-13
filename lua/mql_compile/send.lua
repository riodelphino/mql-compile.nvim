local M = {}

local fn = require('mql_compile.functions')

-- Send (copy) the compiled file to each `send.targets`
---@param opts table
---@param ctx mql_compile.ResultCtx
function M.send(opts, ctx)
   if not opts.send.enabled or not ctx.ok then return end

   if not fn.file_exists(ctx.dest_path) then
      fn.notify("Failed to send\nNot found compiled file: '" .. ctx.dest_path .. "'", vim.log.levels.ERROR)
      return
   end

   local sent = {}
   for _, target in ipairs(opts.send.targets) do
      target = vim.fs.normalize(target) -- Expand '~'
      local ok, path = pcall(opts.send.to, ctx, target)
      if not ok then
         fn.notify('Error in `send.to`:\n' .. tostring(path), vim.log.levels.ERROR)
      elseif path then -- nil: Skip this target
         path = vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))
         local dir = vim.fs.dirname(path)
         -- mkdir
         if not fn.folder_exists(dir) then
            vim.fn.mkdir(dir, 'p')
            if opts.notify.send.on_mkdir then fn.notify("Created dir: '" .. dir .. "'", vim.log.levels.INFO) end
         end
         -- copy
         local copied, err = vim.uv.fs_copyfile(ctx.dest_path, path)
         if copied then
            table.insert(sent, path)
         else
            fn.notify("Failed to send to: '" .. path .. "'\n" .. tostring(err), vim.log.levels.ERROR)
         end
      end
   end

   if opts.notify.send.on_sent and #sent > 0 then
      fn.notify("Sent to:\n'" .. table.concat(sent, "'\n'") .. "'", vim.log.levels.INFO)
   end
end

return M
