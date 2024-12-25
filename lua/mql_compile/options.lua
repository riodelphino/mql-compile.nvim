local M = {}

M._opts = {} -- keep merged options
M._os_type = '' -- keep os_type

M.default = {
   default_ft = 'mql5',
   quickfix = {
      extension = 'qfix',
      auto_open = true, -- Open qfix after compile
      delete_after_load = true,
      keywords = { 'error', 'warning', }, -- Shown in quickfix
      information = {
         notify = true,
         keywords = { 'compiling', 'including', 'code generated' },
      },
   },
   log = {
      extension = 'log',
      delete_after_load = true,
   },
   wine = {
      enabled = true,
      command = 'wine',
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
   notify = {
      information = {
         enabled = true,
         keywords = { 'compiling', 'including', 'code generated' },
      },
      quickfix = {
         on_saved = true,
         on_deleted = true,
      },
      log = {
         on_saved = true,
         on_deleted = true,
      },
   },
}

function M.deep_merge(default, user)
   -- If `user` is not a table, use the `default` value
   if type(user) ~= "table" then
      return default
   end

   -- Iterate through all keys in the default table
   for key, default_value in pairs(default) do
      if user[key] == nil then
         -- If the key is missing in the user table, use the default value
         user[key] = default_value
      elseif type(default_value) == "table" then
         -- If the value is a table, recurse
         user[key] = M.deep_merge(default_value, user[key])
      end
   end
   return user
end


function M.merge(user_opts)
   local opts = {}

   -- opts = vim.tbl_deep_extend("force", M.default, user_opts or {})
   opts = M.deep_merge(M.default, user_opts or {}) -- merge recursively

   -- expand path for % ~
   opts.mql5.metaeditor_path = vim.fn.expand(opts.mql5.metaeditor_path)
   opts.mql5.include_path = vim.fn.expand(opts.mql5.include_path)
   opts.mql5.source_path = vim.fn.expand(opts.mql5.source_path)
   opts.mql4.metaeditor_path = vim.fn.expand(opts.mql4.metaeditor_path)
   opts.mql4.include_path = vim.fn.expand(opts.mql4.include_path)
   opts.mql4.source_path = vim.fn.expand(opts.mql4.source_path)

   -- Set default
   opts.mql5.extension = opts.mql5 and opts.mql5.extension or "mq5"
   opts.mql4.extension = opts.mql4 and opts.mql4.extension or "mq4"

   M._opts = opts

   return opts
end

return M
