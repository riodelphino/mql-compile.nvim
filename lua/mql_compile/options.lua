local M = {}

M._opts = {}
M._os_type = ''
M._root = ''
M._source_path = ''

M.default = {
   priority = { 'mql5', 'mql4' },
   log = {
      extension = 'log',
      delete_after_load = true,
      -- Parsing function from log
      parse = function(line, type)
         local e = {}
         if type == 'error' or type == 'warning' then
            e.filename, e.lnum, e.col, e.type, e.nr, e.text = line:match('^(.*)%((%d+),(%d+)%) : (.*) (%d+): (.*)$')
         elseif type == 'information' then
            e.filename, e.type, e.text = line:match('^(.*) : (.*): (.*)$')
            e.lnum = 1
            e.col = 1
            e.nr = 0
         end
         e.type = e.type:sub(1, 1):upper() -- Convert type to E/W/I/H/N
         return e
      end,
   },
   quickfix = {
      extension = 'qf',
      keywords = { 'error', 'warning' }, --  'error' | 'warning' | 'information'
      auto_open = {
         enabled = true, -- Open qfix after compile
         open_with = { 'error', 'warning' },
      },
   },
   information = {
      show_notify = true,
      extension = 'info',
      actions = { 'including' }, -- 'compiling' | 'including' -- Filtering actions shown in information notify, and also in quickfix.
      delete_after_load = true,
      parse = function(line, i)
         i.file, i.type, i.action, i.details = line:match('^(.-) : (%w+): (%w+) (.+)')
         return i
      end,
      format = function(i) return string.format('%s %s', i.action, i.details) end,
   },
   wine = {
      enabled = true,
      command = 'wine',
   },
   ft = {
      mql5 = {
         metaeditor_path = '',
         include_path = '',
         pattern = '*.mq5',
      },
      mql4 = {
         metaeditor_path = '',
         include_path = '',
         pattern = '*.mq4',
      },
   },
   notify = {
      compile = {
         on_start = true,
         on_failed = true,
         on_succeeded = true,
      },
      information = {
         on_saved = false,
         on_deleted = false,
         -- on_load = false,
         on_count = false,
         actions = { 'including' }, -- 'compiling' | 'including' | 'code generated'
      },
      quickfix = {
         on_updated = false,
      },
      log = {
         on_saved = false,
         on_deleted = false,
         on_count = true,
      },
   },
}

function M.get_opts() return M._opts end

function M.get_os_type() return M._os_type end

function M.deep_merge(default, user)
   fn = require('mql_compile.functions')
   -- If `user` is not a table, use the `default` value
   if type(user) ~= 'table' then return default end

   -- Iterate through all keys in the default table
   for key, default_value in pairs(default) do
      if user[key] == nil then
         -- If the key is missing in the user table, use the default value
         user[key] = default_value
      elseif type(default_value) == 'table' then
         if fn.is_array(default[key]) then -- If the value is a array, just overwrite all by user
            user[key] = user[key]
         else
            -- If the value is a table, recurse
            user[key] = M.deep_merge(default_value, user[key])
         end
      end
   end
   return user
end

function M.merge(user_opts)
   local opts = {}

   -- opts = vim.tbl_deep_extend("force", M.default, user_opts or {})
   opts = M.deep_merge(M.default, user_opts or {})

   M._opts = opts

   return opts
end

return M
