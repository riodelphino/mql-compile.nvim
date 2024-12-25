local M = {}

M._opts = {} -- keep merged options
M._os_type = '' -- keep os_type

M.default = {
   default_ft = 'mql5',
   quickfix = {
      alert_keys = { 'error', 'warning' },
      extension = 'qfix',
      auto_open = true,
      delete_after_load = true,
   },
   log = {
      extension = 'log',
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
}

function M.merge(user_opts)
   local opts = {}
   opts = vim.tbl_deep_extend("force", M.default, user_opts or {})

   opts.mql5.metaeditor_path = vim.fn.expand(opts.mql5.metaeditor_path) -- expand path for % ~ 
   opts.mql5.include_path = vim.fn.expand(opts.mql5.include_path)
   opts.mql5.source_path = vim.fn.expand(opts.mql5.source_path)

   opts.mql4.metaeditor_path = vim.fn.expand(opts.mql4.metaeditor_path)
   opts.mql4.include_path = vim.fn.expand(opts.mql4.include_path)
   opts.mql4.source_path = vim.fn.expand(opts.mql4.source_path)

   opts.mql5.extension = opts.mql5 and opts.mql5.extension or "mq5" -- Set default
   opts.mql4.extension = opts.mql4 and opts.mql4.extension or "mq4"

   M._opts = opts

   return opts
end

return M
