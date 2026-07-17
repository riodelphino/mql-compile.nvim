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
   local default_opts = { title = 'mql-compile', border = 'single' }
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

function M.generate_qf(log_path, types)
   local opts = opt.get_opts()
   local count = {
      -- error = 0,
      -- warning = 0,
      -- information = 0,
   }
   local default_types = { 'error', 'warning', 'information' }
   types = types or default_types -- TODO: Is this needed ??

   -- Checking actions of information
   function is_match_action(line)
      local format = ' : information: %s'
      local matched = false
      for _, action in ipairs(opts.information.actions) do
         search = string.format(format, action)
         matched = matched or line:match(search)
      end
      return matched
   end

   --  bufnr     : buffer number; must be the number of a valid buffer
   --  filename  : name of a file; only used when "bufnr" is not present or it is invalid.
   --  module    : name of a module; if given it will be used in quickfix error window instead of the filename.
   --  lnum      : line number in the file
   --  end_lnum  : end of lines, if the item spans multiple lines
   --  pattern   : search pattern used to locate the error
   --  col       : column number
   --  vcol      : when non-zero: "col" is visual column when zero: "col" is byte index
   --  end_col   : end column, if the item spans multiple columns
   --  nr        : error number
   --  text      : description of the error
   --  type      : single-character error type, 'E', 'W', etc.
   --  valid     : recognized error message
   --  user_data : custom data associated with the item, can be any type.

   local log_file, err_msg, err_code = io.open(log_path, 'r')
   if log_file == nil then
      err_msg = err_msg:gsub('^: ', '')
      msg = string.format('%s: %s', err_msg, log_path)
      M.notify(msg, vim.log.levels.ERROR)
      return nil
   end

   vim.fn.setqflist({}, 'f') -- Clear qflist
   for line in log_file:lines() do
      -- Filter lines
      for _, key in pairs(types) do
         if line:match(' : ' .. key) then
            -- Check for matching action in information
            if key == 'information' then
               if not is_match_action(line) then break end -- exit if not matched in opts.infomration.actions
            end
            if count[key] == nil then count[key] = 0 end
            count[key] = count[key] + 1 -- Count up
            local e = opts.quickfix.parse(line, key) -- Parse log
            if opt._os_type == 'macos' or opt._os_type == 'linux' then -- Convert path delimiters fit to cur OS
               e.filename = e.filename:gsub('\\', '/')
            end
            vim.fn.setqflist({ e }, 'a') -- Add to quickfix
         end
      end
   end
   log_file:close()

   return count
end

function M.generate_info(log_path, actions)
   local opts = opt.get_opts()
   local info_lines = {}
   local count = {
      -- compiling = 0,
      -- including = 0,
   }
   -- local default_types = { 'compiling', 'including' }
   local default_actions = { 'compiling', 'including' }
   actions = actions or default_actions -- TODO: Is this checking & overwriting needed ?

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
            if count[action] == nil then count[action] = 0 end
            count[action] = count[action] + 1
            local i = {}
            -- Parse from log
            i = opts.information.parse(line)
            if M.in_table(actions, i.action) then -- Check for showing in info or not
               -- Format to information
               local formatted = opts.information.format(i)
               table.insert(info_lines, formatted)
            end
         end
      end
   end
   log_file:close()

   -- Generate result string
   local info_content = ''
   for _, line in ipairs(info_lines) do
      info_content = info_content .. line .. '\n'
   end

   -- notify: opts.information.show.notify
   if opts.information.show.notify then
      if info_content ~= '' then
         -- Check action matched in count
         local show_flag = false
         local actions_to_show = opts.information.show.with
         for _, action in ipairs(actions_to_show) do
            if count[action] ~= nil then show_flag = true end
         end
         if show_flag then M.notify(info_content, vim.log.levels.INFO) end
      end
   end

   return count
end

function M.get_ft_list()
   local opts = opt.get_opts()
   return opts.detect.priority -- easier alt for getting from opts.fn
end

function M.get_extension_list()
   local ft_list = M.get_ft_list()
   local ext_list = {}
   for _, ft in ipairs(ft_list) do
      table.insert(ext_list, ft)
   end
   return ext_list
end

function M.get_version(source_path)
   local ver, major, minor
   if fn.file_exists(source_path) then
      local f = io.open(source_path, 'r')
      for line in f:lines() do
         ver = line:match('#property *version *"([0-9%.]+)"')
         if ver then
            major, minor = ver:match('^(%d+)%.(%d+)$')
            break
         end
      end
   end
   local opts = opt.get_opts()
   if opts.notify.rename.on_version then
      if ver then
         M.notify('Version: ' .. ver, vim.log.levels.INFO)
      else
         M.notify('Version not found.', vim.log.levels.INFO)
      end
   end
   -- version = '1.12'
   -- major = '1'
   -- minor = '12'
   return ver, major, minor
end

return M
