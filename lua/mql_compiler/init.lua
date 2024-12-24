local M = {}

local opts = {}
local os_type = ''
local loaded = false

local default_opts = {
   default = 'mql5',
   quickfix = {
      alert_keys = { 'error', 'warning' },
      extension = 'qfix',
   },
   log = {
      extension = 'log',
   },
   mql5 = {
      metaeditor_path = '',
      include_path = '',
      source_path = '',
      extension = 'mq5',
      wine_drive_letter = 'Z:',
      timeout = 5000,
   },
   mql4 = {
      metaeditor_path = '',
      include_path = '',
      source_path = '',
      extension = 'mq4',
      wine_drive_letter = 'Z:',
      timeout = 5000,
   },
}

local function get_os_type()
    if vim.fn.has('win32') == 1 then
        return 'windows'
    elseif vim.fn.has('macunix') == 1 then
        return 'macos'
    else
        return 'linux'
    end
end


function M.setup(_opts)
   if loaded then
      return
   end

   loaded = true

   os_type = get_os_type()

   opts = vim.tbl_deep_extend("force", default_opts, _opts or {})

   opts.mql5.metaeditor_path = vim.fn.expand(opts.mql5.metaeditor_path) -- expand path for % ~ 
   opts.mql5.include_path = vim.fn.expand(opts.mql5.include_path)
   opts.mql5.source_path = vim.fn.expand(opts.mql5.source_path)

   opts.mql4.metaeditor_path = vim.fn.expand(opts.mql4.metaeditor_path)
   opts.mql4.include_path = vim.fn.expand(opts.mql4.include_path)
   opts.mql4.source_path = vim.fn.expand(opts.mql4.source_path)

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
   if (os_type == 'macos') then
      return path:gsub('^' .. drive_letter, ''):gsub('\\', '/')
   end
end

function M.set_source_path(path)
   path = vim.fn.expand(path) -- for % ~ 
   local extension = path:match('%.(.*)$')
   if not extension then
       error("Invalid path: no extension found.")
       return
   end

   -- Determin mql by extension
   if extension == opts.mql5.extension then
       opts.mql5.source_path = path
       print('MQL5 source path set to: ' .. path)
   elseif extension == opts.mql4.extension then
       opts.mql4.source_path = path
       print('MQL4 source path set to: ' .. path)
   else
       error('Unknown file type: ' .. extension .. ". Type must be in 'opts.[mql5/mql4].extension'.")
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
   elseif vim.v.shell_error == 1 then
      print("Finished compile '" .. source_filename .. "' with warnings. Log saved to " .. log_path)
   elseif vim.v.shell_error == 2 then
      error("Failed compile '" .. source_filename .. "'. Log saved to " .. log_path)
   end
end

function M.compile_mql(source_path)
   -- ex.) compile_mql('/path/to/your/file.mq5')
   source_path = vim.fn.expand(source_path)

   -- Automatically change mql5/4 by source_path's extension
   local mql
   if (source_path == nil or source_path == '') then -- Get default mql
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
      else
         error("Invalid file extension")
      end
   end

   -- Set current file path to source_path
   if (mql.source_path == '' and source_path == nil) then -- if no specifications
      local current_file_path = vim.api.nvim_buf_get_name(0)
      if (current_file_path:match('%.'.. mql.extension .. '$')) then
         source_path = current_file_path
      else
         error('No source path is set. and current buffer is not *.' .. mql.extension )
         return
      end
   end

   -- Set paths
   local metaeditor_path = vim.fn.expand(mql.metaeditor_path)
   local log_path = source_path:gsub('%.' .. mql.extension .. '$', '.' .. opts.log.extension)
   log_path = M.convert_path_to_os(log_path, mql.wine_drive_letter)
   local quickfix_path = log_path:gsub('%.log$', '.' .. opts.quickfix.extension)

   -- Compile
   M.compile(metaeditor_path, source_path, log_path)

   -- Convert encoding for mac
   if os_type == 'macos' then
      local utf8_path = log_path .. ".utf8" -- the path converted UTF-8
      local convert_cmd = string.format(
         [[
         iconv -f UTF-16LE -t UTF-8 "%s" > "%s" 2>/dev/null || iconv -f WINDOWS-1252 -t UTF-8 "%s" > "%s" 2>/dev/null || cp "%s" "%s" && tr -d '\r' < "%s" > "%s.tmp" && mv "%s.tmp" "%s"
         ]],
         log_path, utf8_path, -- UTF-16LE → UTF-8
         log_path, utf8_path, -- WINDOWS-1252 → UTF-8
         log_path, utf8_path, -- Copy the file as is
         utf8_path, utf8_path, -- Remove line break code
         utf8_path, utf8_path  -- Overwrite from temporary file
      )
      vim.fn.system(convert_cmd)
   end

   -- Convert log to quickfix format
   local log_file = io.open(log_path .. '.utf8', 'r')
   local quickfix_lines = {}

   for line in log_file:lines() do
      -- Filter alert lines
      for _, alert_key in pairs(opts.quickfix.alert_keys) do
         if line:match(' : ' .. alert_key) then
            local file, line_num, col_num, code, msg

            file, line_num, col_num, code, msg = line:match('^(.*)%((%d+),(%d+)%) : ' .. alert_key .. ' (%d+): (.*)$')
            file = M.convert_path_to_os(file, mql.wine_drive_letter)

            -- Output as quickfix format
            table.insert(quickfix_lines, string.format('%s:%s:%s: ' .. alert_key .. ' %s: %s', file, line_num, col_num, code, msg))
         end
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
   if (os_type == 'macos') then
      os.remove(log_path .. '.utf8')
   end

   print('Quickfix file created: ' .. quickfix_path)

   -- Open quickfix
   vim.cmd('cfile ' .. quickfix_path)
   vim.cmd('copen')
end


return M
