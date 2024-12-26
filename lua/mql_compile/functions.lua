local M = {}

local opt = require('mql_compile.options')

function M.in_table(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

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
   vim.notify(msg, level, { title = 'mql-compile' })
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

function M.log_to_qf(log_path, qf_path, keywords)
   local opts = opt.get_opts()
   local log_file = io.open(log_path, 'r')
   local qf_lines = {}
   local count = {
      error = 0,
      warning = 0,
   }
   local default_keywords = {'error', 'warning'}

   for line in log_file:lines() do
      -- Filter alert lines
      for _, key in pairs(default_keywords) do

         if line:match(' : ' .. key) then
            count[key] = count[key] + 1
            local file, line_num, col_num, code, msg

            file, line_num, col_num, code, msg = line:match('^(.*)%((%d+),(%d+)%) : ' .. key .. ' (%d+): (.*)$')
            file = M.convert_path_to_os(file, opt._mql.wine_drive_letter, opt._os_type)
            if (M.in_table(keywords, key)) then -- Check for showing in qfix
               -- Output as quickfix format
               table.insert(qf_lines, string.format('%s:%s:%s: ' .. key .. ' %s: %s', file, line_num, col_num, code, msg))
            end
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

   -- notify 'quickfix.on_saved'
   if (opts.notify.quickfix.on_saved) then
      msg = "Saved quickfix: '" .. qf_path .. "'"
      M.notify(msg, vim.log.levels.INFO)
   end

   return count

end

function M.log_to_info(log_path, info_path, keywords)
   local opts = opt.get_opts()
   local log_file = io.open(log_path, 'r')
   local info_lines = {}
   local count = {
      compiling = 0,
      including = 0,
   }
   local default_keywords = { 'compiling', 'including' }
   -- local default_keywords = { 'information' }

   for line in log_file:lines() do
      -- Filter alert lines
      for _, key in pairs(default_keywords) do

         if line:match('information: ' .. key) then

            count[key] = count[key] + 1
            local file, line_num, col_num, code, msg

            -- file, line_num, col_num, code, msg = line:match('^(.*)%((%d+),(%d+)%) : ' .. key .. ' (%d+): (.*)$')
            file, level, action, details = line:match("^(.-) : (%w+): (%w+) (.+)")
            file = M.convert_path_to_os(file, opt._mql.wine_drive_letter, opt._os_type)
            if (M.in_table(keywords, key)) then -- Check for showing in info
               -- Output as infomation format
               -- table.insert(info_lines, string.format('[%s] %s %s', file, action, details))
               table.insert(info_lines, string.format('%s %s', action, details))
            end
         end
      end
   end
   log_file:close()

   -- Show result if 'opts.information.show_notify'
   local info_content = ''
   for _, line in ipairs(info_lines) do
      info_content = info_content .. line .. '\n'
   end
   if (opts.information.show_notify) then
      M.notify(info_content, vim.log.levels.INFO)
   end

   -- Save to info
   local info_file = io.open(info_path, 'w')
   for _, line in ipairs(info_lines) do
      info_file:write(line .. '\n')
   end
   info_file:close()

   -- notify 'information.on_saved'
   if (opts.notify.information.on_saved) then
      msg = "Saved info: '" .. info_path .. "'"
      M.notify(msg, vim.log.levels.INFO)
   end

   return count

end


-- Automatically change mql5/4 by source_path's extension
function M.get_source(source_path)
   local opts = opt.get_opts()
   local mql = {}

   source_path = vim.fn.expand(source_path)

   if (source_path == 'v:null' or source_path == nil or source_path == '') then
      source_path = ''
   end

   if (source_path == '') then -- Get default mql
      if (opts.default == 'mql5') then
         mql = opts.mql5
      elseif (opts.default == 'mql4') then
         mql = opts.mql4
      end
      source_path = mql.source_path
   else -- Get mql by extension
      if source_path:match('%.'.. opts.mql5.extension .. '$') then
         mql = opts.mql5
      elseif source_path:match('%.'.. opts.mql4.extension .. '$') then
         mql = opts.mql4
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


function M.get_count_msg(counts, key_value_separator, item_separator)
   key_value_separator = key_value_separator or ': '
   item_separator = item_separator or ' | '
   local msg = ''
   for key, value in pairs(counts) do
      msg = msg .. key .. key_value_separator .. tostring(value) .. item_separator
   end
   if msg:match(item_separator .. '$') then -- remove last item_separator
       msg = msg:sub(1, -(#item_separator + 1))
   end
   return msg
end


function M.is_array(table)
   local is_array_flg = true
   for k, v in pairs(table) do
      if type(k) ~= "number" or type(v) ~= "string" then
         is_array_flg = false
         break
      end
   end
   return is_array_flg
end

function M.get_git_root()
   local git_root = vim.fn.system('git rev-parse --show-toplevel')
   git_root = string.gsub(git_root, '\n$', '')
   if vim.v.shell_error ~= 0 then
      return nil
   end
   return git_root
end

function M.get_root(path)
   local cwd = vim.fn.getcwd()
   local git_root = M.get_git_root(path)
   local current_buf = vim.fn.expand('%:p:h')
   path = path or git_root
   path = path or cwd
   path = path or current_buf
   return path
end

return M


