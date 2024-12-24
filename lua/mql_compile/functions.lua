local M = {}

-- -- local _ = require('mql_compile')
-- local mql = {}
-- local os_type
local opt = require('mql_compile.options')

function M.file_exists(path)
   local file=io.open(path,"r")
   if file ~= nil then
      io.close(file)
      return true
   else
      return false
   end
end

function M.get_os_type()
    if vim.fn.has('win32') == 1 then
        return 'windows'
    elseif vim.fn.has('macunix') == 1 then
        return 'macos'
    else
        return 'linux'
    end
end

function M.notify(msg, level)
   vim.notify(msg, level, { title = 'mql-compiler' })
end

function M.convert_path_to_os(path, drive_letter, os_type)
   if (os_type == 'macos') then
      return path:gsub('^' .. drive_letter, ''):gsub('\\', '/')
   end
end


function M.convert_encoding(path)
   local utf8_path = path .. ".utf8" -- the path converted UTF-8
   local convert_cmd = string.format(
      [[
      iconv -f UTF-16LE -t UTF-8 "%s" > "%s" 2>/dev/null || iconv -f WINDOWS-1252 -t UTF-8 "%s" > "%s" 2>/dev/null || cp "%s" "%s" && tr -d '\r' < "%s" > "%s.tmp" && mv "%s.tmp" "%s"
      ]],
      path, utf8_path, -- UTF-16LE → UTF-8
      path, utf8_path, -- WINDOWS-1252 → UTF-8
      path, utf8_path, -- Copy the file as is
      utf8_path, utf8_path, -- Remove line break code
      utf8_path, utf8_path  -- Overwrite from temporary file
   )
   vim.fn.system(convert_cmd)

   -- rename tmp utf8_path file as path
   local success, err = os.rename(utf8_path, path)
   if not success then
       M.notify(err, vim.log.levels.ERROR)
   end
end

function M.log_to_qf(log_path, qf_path, alert_keys)
   local log_file = io.open(log_path, 'r')
   local qf_lines = {}

   for line in log_file:lines() do
      -- Filter alert lines
      for _, alert_key in pairs(alert_keys) do
         if line:match(' : ' .. alert_key) then
            local file, line_num, col_num, code, msg

            file, line_num, col_num, code, msg = line:match('^(.*)%((%d+),(%d+)%) : ' .. alert_key .. ' (%d+): (.*)$')
            file = M.convert_path_to_os(file, opt._mql.wine_drive_letter, opt._os_type)

            -- Output as quickfix format
            table.insert(qf_lines, string.format('%s:%s:%s: ' .. alert_key .. ' %s: %s', file, line_num, col_num, code, msg))
         end
      end
   end
   log_file:close()

   -- Save to quickfix
   local qf_file = io.open(qf_path, 'w')
   for _, line in ipairs(qf_lines) do
      qf_file:write(line .. '\n')
   end
   qf_file:close()

   -- msg = 'Quickfix file created: ' .. qf_path
   -- M.notify(msg, vim.log.levels.INFO)

end

function M.get_source(source_path)
   -- Automatically change mql5/4 by source_path's extension
   local mql = {}

   source_path = vim.fn.expand(source_path)

   if (source_path == 'v:null' or source_path == nil or source_path == '') then
      source_path = ''
   end

   if (source_path == '') then -- Get default mql
      if (opt._opts.default == 'mql5') then
         mql = opt._opts.mql5
      elseif (opt._opts.default == 'mql4') then
         mql = opt._opts.mql4
      end
      source_path = mql.source_path
   else -- Get mql by extension
      if source_path:match('%.'.. opt._opts.mql5.extension .. '$') then
         mql = opt._opts.mql5
      elseif source_path:match('%.'.. opt._opts.mql4.extension .. '$') then
         mql = opt._opts.mql4
      -- else
      --    error("Invalid file extension")
      end
   end
   -- Set current file path to source_path
   if (mql.source_path == '' and source_path == nil) then -- if no specifications
      local current_file_path = vim.api.nvim_buf_get_name(0)
      if (current_file_path:match('%.'.. mql.extension .. '$')) then
         source_path = current_file_path
      else
         msg = 'No source path is set. and current buffer is not *.' .. mql.extension
         M.notify(msg, vim.log.levels.ERROR)
         return
      end
   end
   return source_path, mql
end

return M

