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
      parse = function(line, e)
         if e.type == 'error' or e.type == 'warning' then
            e.file, e.line, e.col, e.code, e.msg = line:match('^(.*)%((%d+),(%d+)%) : ' .. e.type .. ' (%d+): (.*)$')
         elseif e.type == 'information' then
            e.file, e.msg = line:match('^(.*) : ' .. e.type .. ': (.*)$')
         end
         return e
      end,
   },
   quickfix = {
      extension = 'qf',
      -- keywords = { 'error' }, --  'error' | 'warning'
      keywords = { 'error', 'warning' }, --  'error' | 'warning' | 'information'
      auto_open = {
         enabled = true, -- Open qfix after compile
         -- open_with = { },
         open_with = { 'error', 'warning' },
      },
      delete_after_load = true,
      -- Formatting function for generating quickfix
      format = function(e)
         if e.type == 'error' or e.type == 'warning' then
            return string.format('%s:%d:%d: %s:%s: %s', e.file, e.line, e.col, e.type, e.code, e.msg)
         elseif e.type == 'information' then
            return string.format('%s:1:1: %s: %s', e.file, e.type, e.msg)
         end
      end,
   },
   information = {
      show_notify = true,
      extension = 'info',
      actions = { 'including' }, -- 'compiling' | 'including'
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
         wine_drive_letter = 'Z:',
         timeout = 5000,
      },
      mql4 = {
         metaeditor_path = '',
         include_path = '',
         pattern = '*.mq4',
         wine_drive_letter = 'Z:',
         timeout = 5000,
      },
   },
   notify = {
      compile = {
         on_start = false,
         on_failed = true,
         on_succeeded = true,
      },
      information = {
         on_saved = false,
         on_deleted = false,
         -- on_load = false,
         counts = false,
         actions = { 'including' }, -- 'compiling' | 'including' | 'code generated'
      },
      quickfix = {
         on_saved = false,
         on_deleted = false,
      },
      log = {
         on_saved = false,
         on_deleted = false,
         counts = true,
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

   -- expand path for % ~
   opts.ft.mql5.metaeditor_path = vim.fn.expand(opts.ft.mql5.metaeditor_path)
   opts.ft.mql5.include_path = vim.fn.expand(opts.ft.mql5.include_path)
   opts.ft.mql5.source_path = vim.fn.expand(opts.ft.mql5.source_path)
   opts.ft.mql4.metaeditor_path = vim.fn.expand(opts.ft.mql4.metaeditor_path)
   opts.ft.mql4.include_path = vim.fn.expand(opts.ft.mql4.include_path)
   opts.ft.mql4.source_path = vim.fn.expand(opts.ft.mql4.source_path)

   -- Set default
   opts.ft.mql5.extension = opts.ft.mql5 and opts.ft.mql5.extension or 'mq5'
   opts.ft.mql4.extension = opts.ft.mql4 and opts.ft.mql4.extension or 'mq4'

   M._opts = opts

   return opts
end

return M
