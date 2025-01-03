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
   },
   quickfix = {
      types = { 'error', 'warning' }, -- Types to pick up. 'error' | 'warning' | 'information'
      show = {
         copen = true, -- Open quickfix automatically
         with = { 'error', 'warning' }, -- Types to copen. 'error' | 'warning' | 'information'
      },
      parse = function(line, type) -- Parsing function from log
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
   information = {
      actions = { 'including' }, -- Actions to pick up. 'compiling' | 'including'
      show = {
         notify = true,
         with = { 'including' }, -- Actions to show. 'compiling' | 'including'
      },
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
         include_path = '', -- Not supported now
         pattern = '*.mq5',
      },
      mql4 = {
         metaeditor_path = '',
         include_path = '', -- Not supported now
         pattern = '*.mq4',
      },
   },
   notify = { -- Enable/disable notify
      compile = {
         on_started = true,
         on_finished = true,
      },
      log = {
         on_saved = false,
         on_deleted = false,
      },
      quickfix = {
         on_finished = true, -- Add quickfix counts to main message
      },
      information = {
         on_generated = true, -- Show informations on notify
      },
      levels = { -- Color to notify if compiling was ...
         succeeded = { -- with type ...
            none = vim.log.levels.INFO, -- *.OFF is also good. (but maybe same color)
            info = vim.log.levels.INFO,
            warn = vim.log.levels.WARN, -- *.INFO is also good, if you don't like warn color on success.
         },
         failed = vim.log.levels.ERROR,
         information = vim.log.levels.INFO, -- for informations. *.OFF is also good. (but maybe same color)
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
