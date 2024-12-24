local M = {}

local opts = {}

local default_opts = {
   os = 'macos', -- 'macos' | 'windows'
   mql5 = {
      metaeditor_path = '',
      include_path = vim.fn.expand(''),
      extension = 'mq5',
      wine_drive_letter = 'Z:',
      timeout = 5000,
   },
   mql4 = {
      metaeditor_path = '',
      include_path = vim.fn.expand(''),
      extension = 'mq4',
      wine_drive_letter = 'Z:',
      timeout = 5000,
   },
}

function M.setup(_opts)
   if loaded then
      return
   end

   loaded = true

   opts = vim.tbl_deep_extend("force", default_opts, _opts or {})

   opts.mql5.metaeditor_path = vim.fn.expand(opts.mql5.metaeditor_path) -- expand path
   opts.mql5.include_path = vim.fn.expand(opts.mql5.include_path)

   opts.mql4.metaeditor_path = vim.fn.expand(opts.mql4.metaeditor_path)
   opts.mql4.include_path = vim.fn.expand(opts.mql4.include_path)

   opts.mql5.extension = opts.mql5 and opts.mql5.extension or "mq5" -- Set default
   opts.mql4.extension = opts.mql4 and opts.mql4.extension or "mq4"


   -- Set Commands
   -- :MQLCompilerSetSourc
   vim.api.nvim_create_user_command(
      "MQLCompilerSetSource",
      function(cmd_opts)
         M.set_source_path(cmd_opts.args)
      end,
      { nargs = 1 }
   )

   -- :MQLCompiler
   vim.api.nvim_create_user_command(
      "MQLCompiler",
      function(cmd_opts)
         M.compile_mql(opts.args ~= "" and cmd_opts.args or nil)
      end,
      { nargs = "?" }
   )
end

function M.convert_path_to_os(path, drive_letter)
   if (opts.os == 'macos') then
      return path:gsub('^' .. drive_letter, ''):gsub('\\', '/')
   end
end

function M.set_source_path(path)
    local extention = path:match('%.(.*)$')
    if not extention then
        print("Invalid path: no extension found.")
        return
    end

    -- デフォルトの拡張子を設定
    local mql5_ext = opts.mql5 and opts.mql5.extention or "mq5"
    local mql4_ext = opts.mql4 and opts.mql4.extention or "mq4"

    -- 拡張子に応じてパスを設定
    if extention == mql5_ext then
        opts.mql5.source_path = path
        print('MQL5 source path set to: ' .. path)
    elseif extention == mql4_ext then
        opts.mql4.source_path = path
        print('MQL4 source path set to: ' .. path)
    else
        print('Unknown file type: ' .. extention .. ". Type must be in 'opts.[mql5/mql4].extension'.")
    end
end

function M.compile(metaeditor_path, source_path, log_path)
   -- Compile
   local compile_cmd = string.format('wine "%s" /compile:"%s" /log:"%s"', metaeditor_path, source_path, log_path)
   local compile_result = vim.fn.system(compile_cmd)

   -- Check result
   local source_filename = source_path:match("([^/\\]+)$")
   if vim.v.shell_error == 0 then
      print("Finished compile '" .. source_filename .. "'. Log saved to " .. log_path)
   else
      print("Failed compile '" .. source_filename .. "'. Log saved to " .. log_path)
   end
end

function M.compile_mql(source_path)
   -- ex.) compile_mql('/path/to/your/file.mq5')
   local mql

   -- Automatically change mql5/4 by source_path's extension
   if (source_path ~= nil) then
      if source_path:match('%.'.. opts.mql5.extension .. '$') then
         mql = opts.mql5
      elseif source_path:match('%.'.. opts.mql4.extension .. '$') then
         mql = opts.mql4
      end
   else
      mql = opts.mql5 -- default
   end

   -- Set current file path if source_path == ''
   local current_file_path = vim.api.nvim_buf_get_name(0)
   if (source_path == '') then
      if (current_file_path:match('%.'.. mql.extension .. '$')) then
         source_path = current_file_path
      else
         print('No source path is set. and current buffer is not *.' .. mql.extension )
         return
      end
   end

   -- Set paths
   local metaeditor_path = vim.fn.expand(mql.metaeditor_path)
   local log_path = source_path:gsub('%.' .. mql.extension .. '$', '.log')
   log_path = M.convert_path_to_os(log_path)
   local quickfix_path = log_path:gsub('%.log$', '.quickfix')

   -- Convert encoding for mac
   if (opts.os == 'macos') then
      local convert_cmd = string.format('iconv -f UTF-16LE -t UTF-8 %s > %s.utf8 || iconv -f WINDOWS-1252 -t UTF-8 %s > %s.utf8 || cp %s %s.utf8', log_path, log_path, log_path, log_path, log_path, log_path)
      vim.fn.system(convert_cmd)
   end

   -- Read log / Convert to quickfix format
   local log_file = io.open(log_path .. '.utf8', 'r')
   local quickfix_lines = {}

   for line in log_file:lines() do
      -- Filter 'error' lines
      if line:match(' : error') then
         local file, line_num, col_num, error_code, error_msg

         file, line_num, col_num, error_code, error_msg = line:match('^(.*)%((%d+),(%d+)%) : error (%d+): (.*)$')
         file = M.convert_path_to_os(file)

         -- Output as quickfix format
         table.insert(quickfix_lines, string.format('%s:%s:%s: Error %s: %s', file, line_num, col_num, error_code, error_msg))
      end
   end
   log_file:close()

   -- Save to quickfix
   local quickfix_file = io.open(quickfix_path, 'w')
   for _, line in ipairs(quickfix_lines) do
      quickfix_file:write(line .. '\n')
   end
   quickfix_file:close()

   -- Delete tmp file for mac
   if (opts == 'macos') then
      os.remove(log_path .. '.utf8')
   end

   print('Quickfix file created: ' .. quickfix_path)

   -- Open quickfix
   vim.cmd('cfile ' .. quickfix_path)
   vim.cmd('copen')
end


return M
