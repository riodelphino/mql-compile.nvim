local M = {}

local opt = require('mql_compile.options')
M = vim.tbl_deep_extend('force', M, require('mql_compile.functions.path'))
M = vim.tbl_deep_extend('force', M, require('mql_compile.functions.core'))
M = vim.tbl_deep_extend('force', M, require('mql_compile.functions.string'))
M = vim.tbl_deep_extend('force', M, require('mql_compile.functions.table'))

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
   opts = vim.tbl_deep_extend('force', default_opts, opts or {})
   vim.notify(msg, level, opts)
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
   local qf_lines = {}
   local count = {
      error = 0,
      warning = 0,
      information = 0,
   }
   local default_keywords = { 'error', 'warning', 'information' }
   keywords = keywords or default_keywords

   local log_file, err_msg, err_code = io.open(log_path, 'r')
   if log_file == nil then
      err_msg = err_msg:gsub('^: ', '')
      msg = string.format('%s: %s', err_msg, log_path)
      M.notify(msg, vim.log.levels.ERROR)
      return nil
   end
   for line in log_file:lines() do
      -- Filter lines
      for _, key in pairs(keywords) do
         if line:match(' : ' .. key) then
            count[key] = count[key] + 1
            local e = {}
            -- local file, line_num, col_num, code, msg

            e.type = key
            e = opts.log.parse(line, e) -- Parse log !

            -- e.file = M.convert_path_to_os(e.file, opt._mql.wine_drive_letter, opt._os_type)

            if M.in_table(keywords, key) then -- Check for showing in qfix
               -- Output as quickfix format
               local formatted_line = opts.quickfix.format(e) -- Format log to quickfix!
               table.insert(qf_lines, formatted_line)
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

function M.log_to_info(log_path, info_path, actions)
   local opts = opt.get_opts()
   local info_lines = {}
   local count = {
      compiling = 0,
      including = 0,
   }
   -- local default_keywords = { 'compiling', 'including' }
   local default_actions = { 'compiling', 'including' }
   actions = actions or default_actions

   local log_file, err_msg, err_code = io.open(log_path, 'r')
   if log_file == nil then
      err_msg = err_msg:gsub('^: ', '')
      msg = string.format('%s: %s', err_msg, log_path)
      M.notify(msg, vim.log.levels.ERROR)
      return nil
   end

   for line in log_file:lines() do
      -- Filter lines
      for _, action in pairs(actions) do
         if line:match('information: ' .. action) then
            count[action] = count[action] + 1
            local i = {}

            i.file, i.type, i.action, i.details = line:match('^(.-) : (%w+): (%w+) (.+)')
            -- i.file = M.convert_path_to_os(i.file, opt._mql.wine_drive_letter, opt._os_type)
            if M.in_table(actions, i.action) then -- Check for showing in info
               -- Output as infomation format
               -- table.insert(info_lines, string.format('[%s] %s %s', file, action, details))
               local formatted = opts.information.format(i)
               table.insert(info_lines, formatted)
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

function M.get_ft_list()
   local opts = opt.get_opts()
   -- local ft_list = {}
   -- for ft_key, ft in pairs(opts.ft) do
   --    table.insert(ft_list, ft_key)
   -- end
   local ft_list = opts.priority
   return ft_list
end

-- Automatically change mql5/4 by source_path's extension
function M.get_source(source_path)
   local opts = opt.get_opts()
   local mql = {}
   local ft_list = M.get_ft_list()

   -- Adjust arg source_path
   source_path = vim.fn.expand(source_path)
   if source_path == 'v:null' or source_path == '' or source_path == nil then source_path = nil end
   if source_path ~= nil then -- Has some source_path
      for _, ft_key in ipairs(ft_list) do -- Loop for ft list
         local pattern = M.pattern_bash_to_lua(opts.ft[ft_key].pattern) -- Convert pattern to lua
         if source_path:match(pattern) then -- Check pattern
            if M.file_exists(source_path) then -- Check file exists
               mql = opts.ft[ft_key]
               return M.get_relative_path(source_path), mql
            else
               local msg = 'File does not exist: ' .. source_path
               M.notify(msg, vim.log.levels.ERROR)
               return nil, nil
            end
         end
      end
      local msg = 'Patterns are not matched: ' .. M.get_relative_path(source_path)
      M.notify(msg, vim.log.levels.ERROR)
      return nil, nil
   else -- No specify arg source_path
      local current_filename = vim.api.nvim_buf_get_name(0) -- Check for current filename
      if current_filename ~= '' and current_filename ~= nil then -- Has filename
         for _, ft_key in pairs(ft_list) do -- Loop for ft list
            local pattern = M.pattern_bash_to_lua(opts.ft[ft_key].pattern) -- Convert pattern to lua
            if current_filename:match(pattern) then -- Check pattern
               mql = opts.ft[ft_key]
               source_path = current_filename
               return source_path, mql
            end
         end
      end

      -- No current filename or not matched filetype
      local git_root_dir = M.get_git_root() -- Check for git root
      if git_root_dir ~= '' and git_root_dir ~= nil then -- Has git root
         for _, ft_key in ipairs(ft_list) do -- Loop for ft list
            local pattern = M.pattern_bash_to_lua(opts.ft[ft_key].pattern) -- Convert pattern to lua
            local find_list = M.find_files_recursively(git_root_dir, pattern)
            if #find_list > 0 then
               source_path = find_list[1]
               mql = opts.ft[ft_key]
               return source_path, mql
            end
         end
      end

      -- No git root, or No files in git root
      local cwd_dir = vim.fn.getcwd() -- Check for cwd
      if cwd_dir ~= '' and cwd_dir ~= nil then
         for _, ft_key in ipairs(ft_list) do -- Loop for ft list
            local pattern = M.pattern_bash_to_lua(opts.ft[ft_key].pattern) -- Convert pattern to lua
            local find_list = M.find_files_recursively(cwd_dir, pattern)
            if #find_list > 0 then
               source_path = find_list[1]
               mql = opts.ft[ft_key]
               return source_path, mql
            end
         end
      end
   end
   -- No files found at all
   msg = 'No files found.'
   vim.notify(msg, vim.log.levels.ERROR)
   return nil, nil
end

function get_ft_list()
   local opts = opt.get_opts()
   return opts.priority -- easier alt for getting from opts.fn
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
   local sep = M.get_path_separator()
   local mql = {}
   local msg = ''

   if path == 'v:null' or path == nil or path == '' then
      path = vim.api.nvim_buf_get_name(0) -- get current file path
   end

   path = vim.fn.expand(path) -- for % ~
   path, mql = M.get_source(path)
   if path == nil then return end

   -- Determin mql by extension
   for ft_key, ft in pairs(opts.ft) do
      local pattern = M.pattern_bash_to_lua(ft.pattern)
      if path:match(pattern) then
         path = M.get_relative_path(path)
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

return M
