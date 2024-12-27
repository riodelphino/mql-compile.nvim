local M = {}

local opt = require('mql_compile.options')

function M.in_table(tbl, value)
   for _, v in pairs(tbl) do
      if v == value then return true end
   end
   return false
end

function M.file_exists(path)
   local file = io.open(path, 'r')
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

function M.notify(msg, level, opts)
   local default_opts = { title = 'mql-compile' }
   if opts == nil then opts = vim.tbl_deep_extend('force', default_opts, opts or {}) end
   vim.notify(msg, level, opts)
end

function M.convert_path_to_os(path, drive_letter, os_type)
   if os_type == 'macos' then return path:gsub('^' .. drive_letter, ''):gsub('\\', '/') end
end

function M.convert_encoding(path)
   local utf8_path = path .. '.utf8' -- the path converted UTF-8
   local convert_cmd = string.format(
      [[
      iconv -f UTF-16LE -t UTF-8 "%s" > "%s" 2>/dev/null || iconv -f WINDOWS-1252 -t UTF-8 "%s" > "%s" 2>/dev/null || cp "%s" "%s" && tr -d '\r' < "%s" > "%s.tmp" && mv "%s.tmp" "%s"
      ]],
      path,
      utf8_path, -- UTF-16LE → UTF-8
      path,
      utf8_path, -- WINDOWS-1252 → UTF-8
      path,
      utf8_path, -- Copy the file as is
      utf8_path,
      utf8_path, -- Remove line break code
      utf8_path,
      utf8_path -- Overwrite from temporary file
   )
   vim.fn.system(convert_cmd)

   -- rename tmp utf8_path file as path
   local success, err = os.rename(utf8_path, path)
   if not success then M.notify(err, vim.log.levels.ERROR) end
end

function M.log_to_qf(log_path, qf_path, keywords)
   local opts = opt.get_opts()
   local log_file = io.open(log_path, 'r')
   local qf_lines = {}
   local count = {
      error = 0,
      warning = 0,
   }
   local default_keywords = { 'error', 'warning' }

   for line in log_file:lines() do
      -- Filter alert lines
      for _, key in pairs(default_keywords) do
         if line:match(' : ' .. key) then
            count[key] = count[key] + 1
            local file, line_num, col_num, code, msg

            file, line_num, col_num, code, msg = line:match('^(.*)%((%d+),(%d+)%) : ' .. key .. ' (%d+): (.*)$')
            file = M.convert_path_to_os(file, opt._mql.wine_drive_letter, opt._os_type)
            if M.in_table(keywords, key) then -- Check for showing in qfix
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
   if opts.notify.quickfix.on_saved then
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
            file, level, action, details = line:match('^(.-) : (%w+): (%w+) (.+)')
            file = M.convert_path_to_os(file, opt._mql.wine_drive_letter, opt._os_type)
            if M.in_table(keywords, key) then -- Check for showing in info
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
   if opts.information.show_notify then M.notify(info_content, vim.log.levels.INFO) end

   -- Save to info
   local info_file = io.open(info_path, 'w')
   for _, line in ipairs(info_lines) do
      info_file:write(line .. '\n')
   end
   info_file:close()

   -- notify 'information.on_saved'
   if opts.notify.information.on_saved then
      msg = "Saved info: '" .. info_path .. "'"
      M.notify(msg, vim.log.levels.INFO)
   end

   return count
end

function M.get_extension_by_ft(ft)
   local opts = opt.get_opts()
   return opts[ft].extension
end

-- Automatically change mql5/4 by source_path's extension
function M.get_source(source_path)
   local opts = opt.get_opts()
   local mql = {}
   local ft_list = M.get_ft_list()
   local ext_list = M.get_extension_list()

   -- Adjust arg source_path
   source_path = vim.fn.expand(source_path)
   if source_path == 'v:null' or source_path == nil or source_path == '' then -- Unity 'v:null', nil, '' to ''
      source_path = ''
   end
   if source_path ~= '' then -- Has some source_path
      if M.file_exists(source_path) then -- Check file exists
         for ft in ipairs(ft_list) do -- Loop for ft list
            local pattern = M.pattern_bash_to_lua(opts.ft[ft].pattern) -- Convert pattern to lua
            if source_path:match(pattern) then -- Check pattern
               return source_path, nil
            end
         end
         local msg = 'Filetype is not matched.'
         fn.notify(msg, vim.log.levels.ERROR)
      else
         local msg = 'File not exists.'
         fn.notify(msg, vim.log.levels.ERROR)
      end
   else -- No specify source_path
      local current_filename = vim.api.nvim_buf_get_name(0) -- Check for current filename
      if current_filename ~= '' and current_filename ~= nil then -- Has filename
         for ft in ipairs(ft_list) do -- Loop for ft list
            local pattern = M.pattern_bash_to_lua(opts.ft[ft].pattern) -- Convert pattern to lua
            if current_filename:match(pattern) then -- Check pattern
               mql = opts.ft[ft]
               return source_path, mql
            end
         end
      else -- No filename
         local git_root_dir = M.get_git_root() -- Check for git root
         if git_root_dir ~= '' and git_root_dir ~= nil then -- Has git root
            for ft in ipairs(ft_list) do -- Loop for ft list
               local pattern = M.pattern_bash_to_lua(opts.ft[ft].pattern) -- Convert pattern to lua
               local find_list = M.find_files_recursively(git_root_dir, pattern)
               if #find_list > 0 then
                  source_path = find_list[1]
                  mql = opts.ft[ft]
                  return source_path, mql
               end
            end
         else -- No git root, or No files in git root
            local cwd_dir = vim.fn.getcwd() -- Check for cwd
            if cwd_dir ~= '' and cwd_dir ~= nil then
               for ft in ipairs(ft_list) do -- Loop for ft list
                  local pattern = M.pattern_bash_to_lua(opts.ft[ft].pattern) -- Convert pattern to lua
                  local find_list = M.find_files_recursively(git_root_dir, pattern)
                  if #find_list > 0 then
                     source_path = find_list[1]
                     mql = opts.ft[ft]
                     return source_path, mql
                  end
               end
            end
         end
      end
   end

   -- if (source_path == '') then -- Get default mql
   --    if (opts.default_ft == 'mql5') then
   --       mql = opts.mql5
   --    elseif (opts.default_ft == 'mql4') then
   --       mql = opts.mql4
   --    end
   --    source_path = mql.source_path
   -- else -- Get mql by extension
   --    if source_path:match('%.'.. opts.mql5.extension .. '$') then
   --       mql = opts.mql5
   --    elseif source_path:match('%.'.. opts.mql4.extension .. '$') then
   --       mql = opts.mql4
   --    -- else
   --    --    error("Invalid file extension")
   --    end
   -- end
   -- -- Set current file path to source_path
   -- if (mql.source_path == '' and source_path == nil) then -- if no specifications
   --    local current_file_path = vim.api.nvim_buf_get_name(0)
   --    if (current_file_path:match('%.'.. mql.extension .. '$')) then
   --       source_path = current_file_path
   --    else
   --       local find = '\\*.' .. mql.extension
   --       source_path = M.detect_file(M.get_root(), find)
   --       if (source_path == nil or source_path == '') then
   --          msg = 'Source error:\n  - Source path is not set. \n  - Current buffer is not *.' .. mql.extension .. '.\n  - Cannot detect *.' .. mql.extension .. ' in root.'
   --          M.notify(msg, vim.log.levels.ERROR)
   --          return
   --       end
   --    end
   -- end
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
      if type(k) ~= 'number' or type(v) ~= 'string' then
         is_array_flg = false
         break
      end
   end
   return is_array_flg
end

function M.get_git_root()
   local git_root = vim.fn.system('git rev-parse --show-toplevel')
   git_root = string.gsub(git_root, '\n$', '')
   if vim.v.shell_error ~= 0 then return nil end
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

function M.detect_file(path, filename)
   path = path or M.get_root()
   local find_cmd = 'find ' .. path .. ' -name ' .. filename
   local result = vim.fn.system(find_cmd)
   if result == nil or result == '' then return nil end
   print(find_cmd)
   -- print(find)
   find_list = M.split(result, '\n')
   -- print(#find_list)
   if #find_list == 0 then
      return result
   else
      return find_list[1] -- just return first file
   end
end

-- split a string
function M.split(str, delimiter)
   local result = {}
   local from = 1
   local delim_from, delim_to = string.find(str, delimiter, from, true)
   while delim_from do
      if delim_from ~= 1 then table.insert(result, string.sub(str, from, delim_from - 1)) end
      from = delim_to + 1
      delim_from, delim_to = string.find(str, delimiter, from, true)
   end
   if from <= #str then table.insert(result, string.sub(str, from)) end
   return result
end

function file_exists(filename)
   local file = io.open(filename, 'r')
   if file ~= nil then
      io.close(file)
      return true
   else
      return false
   end
end

function get_ft_list()
   local opts = opt.get_opts()
   return opts.priority -- FIXME: this must return opts.ft 's first children
end

function get_extension_list()
   local ft_list = M.get_ft_list()
   local ext_list = {}
   for _, ft in ipairs(ft_list) do
      table.insert(ext_list, ft)
   end
   return ext_list
end

function M.set_source_path(path)
   local opts = opt.get_opts()
   local msg = ''

   if path == 'v:null' or path == nil or path == '' then
      path = vim.api.nvim_buf_get_name(0) -- get current file path
   end

   path = vim.fn.expand(path) -- for % ~

   -- Determin mql by extension
   for ft_key, ft in pairs(opts.ft) do
      local pattern = M.pattern_bash_to_lua(ft.pattern)
      if path:match(pattern) then
         path = path:gsub(M.get_root() .. '/', '')
         opt._source_path = path
         msg = 'Source path is set to: ' .. path .. ' (' .. ft_key .. ')'
         M.notify(msg, vim.log.levels.INFO)
         return
      end
   end

   local extension = M.get_extension_by_filename(path)
   msg = 'Unknown file type: ' .. extension .. "\nType must be in 'opts.ft.*.pattern'."
   M.notify(msg, vim.log.levels.ERROR)
end

function M.get_extension_by_filename(filename, fallback_to_filename)
   fallback_to_filename = fallback_to_filename == nil or true
   local extension = filename:match('%.(.*)$')
   if extension == nil and fallback_to_filename then extension = filename:match('^.+/(.-)$') end
   return extension
end

-- Luaパターン -> Bashパターン
function M.pattern_lua_to_bash(lua_pattern)
   -- Luaの正規表現にある特殊文字を変換
   local bash_pattern = lua_pattern
      :gsub('%%.', '%%') -- `%` は Bash パターンのエスケープをそのまま維持
      :gsub('%.', '?') -- `.` は Bash パターンの `?` に対応
      :gsub('%%%*', '*') -- `%%*` は Bash の `*` に対応
      :gsub('%%%+', '*') -- Luaの`+` (1文字以上) は Bash の `*` (0文字以上)
      :gsub('%%%-', '-') -- `%%-` はそのまま `-` に
      :gsub('%%%(', '(') -- `%(` を `(` に
      :gsub('%%%)', ')') -- `%)` を `)` に
      :gsub('%%%[', '[') -- `%[` を `[` に
      :gsub('%%%]', ']') -- `%]` を `]` に
   return bash_pattern
end

-- Bashパターン -> Luaパターン
function M.pattern_bash_to_lua(bash_pattern)
   -- BashのワイルドカードをLuaパターンに変換
   local lua_pattern = bash_pattern
      :gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1') -- Lua用に特殊文字をエスケープ
      :gsub('%%%*', '.*') -- Bashの `*` を Luaの `.*` に
      :gsub('%%%?', '.') -- Bashの `?` を Luaの `.` に
   return lua_pattern
end

function M.find_files_recursively(base_dir, pattern)
   local files = {}
   local uv = vim.loop

   local function scan_dir(dir)
      local handle = uv.fs_scandir(dir)
      if not handle then return end

      while true do
         local name, type = uv.fs_scandir_next(handle)
         if not name then break end

         local full_path = dir .. '/' .. name
         if type == 'directory' then
            scan_dir(full_path) -- 再帰的に探索
         elseif type == 'file' and name:match(pattern) then
            table.insert(files, full_path)
         end
      end
   end

   scan_dir(base_dir)
   return files
end

return M
