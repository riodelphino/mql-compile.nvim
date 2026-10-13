local M = {}

M._opts = {}
M._base_opts = {} -- Global opts merged with user opts (without project config)
M._os_type = ''
-- M._source_path = ''
M._source_path = nil

M.default = {
   root_marker = { '.editorconfig', '.gitignore', '.git', '.clangd', '.clang-format', 'cpplint.cfg' },
   ft = {
      mql5 = {
         wine_path = '', -- wine command path. (leave it '' on windows)
         metaeditor_path = '', -- 'metaeditor64.exe' path
         include_path = '', -- Not supported now
         extension = {
            source = 'mq5',
            compiled = 'ex5',
         },
         overwrite = true,
      },
      mql4 = {
         wine_path = '', -- wine command path. (leave it '' on windows)
         metaeditor_path = '', -- 'metaeditor.exe' path
         include_path = '', -- Not supported now
         extension = {
            source = 'mq4',
            compiled = 'ex4',
         },
         overwrite = true,
      },
   },
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
      parse = function(line)
         local i = {}
         i.file, i.type, i.action, i.details = line:match('^(.-) : (%w+): (%w+) (.+)')
         return i
      end,
      format = function(i)
         local formated = string.format('%s %s', i.action, i.details)
         return formated
      end,
   },
   rename = {
      enabled = true,
      ---@param ctx mql_compile.Ctx
      to = function(ctx)
         if ctx.ver == nil or ctx.ver == '' then
            return string.format('archive/%s.%s', ctx.fname, ctx.ext) -- archive/myea.ex5
         else
            return string.format('archive/%s_v%s.%s', ctx.fname, ctx.ver, ctx.ext) -- archive/myea_ver1.10.ex5
         end
      end,
   },
   send = {
      enabled = false,
      targets = {}, -- Base dirs to send the compiled file to (e.g. '~/VPS/shared/ea')
      ---@param ctx mql_compile.ResultCtx
      ---@param target string  A dir in `send.targets` ('~' is expanded)
      ---@return string?       Path to send the compiled file to. (nil: skip this target)
      to = function(ctx, target)
         local relpath = vim.fs.relpath(ctx.root, ctx.dest_path) or vim.fs.basename(ctx.dest_path)
         return vim.fs.joinpath(target, ctx.project, relpath) -- <target>/<project>/mt5/myea.ex5
      end,
   },
   hooks = {
      -- pre = function(ctx) end, -- Called before compiling. Return false to abort. (ctx: mql_compile.Ctx)
      -- post = function(ctx) end, -- Called after compiling (and renaming). (ctx: mql_compile.ResultCtx)
   },
   notify = { -- Enable/disable notify
      debug = {
         compile = {
            show_cmd = false,
            show_cwd = false,
         },
      },
      compile = {
         on_started = true,
         on_finished = true,
      },
      log = {
         on_generated = false,
         on_deleted = false,
      },
      quickfix = {
         on_finished = true, -- Append each type counts of quickfix, on `notify.compile.on_finished`
      },
      information = {
         on_generated = true, -- Show informations on notify
      },
      rename = {
         on_mkdir = false,
         on_version = false,
         on_renamed = true,
      },
      send = {
         on_mkdir = false,
         on_sent = true,
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
      show_title = false,
   },
   highlights = { -- Highlights on quickfix window
      enabled = true,
      hl_prefix = 'qf',
      hl_groups = {
         filename = { 'FileName', { link = 'Directory' } }, -- '<Highlight name>' , { <highlight options> }
         separator_left = { 'SeparatorLeft', { fg = '#cccccc' } },
         separator_right = { 'SeparatorRight', { fg = '#cccccc' } },
         line_nr = { 'LineNr', { fg = '#888888' } },
         col = { 'Col', { fg = '#888888' } },
         error = { 'Error', { link = 'DiagnosticError' } },
         warning = { 'Warning', { link = 'DiagnosticWarn' } },
         info = { 'Info', { link = 'DiagnosticInfo' } },
         hint = { 'Hint', { link = 'DiagnosticHint' } },
         note = { 'Note', { link = 'DiagnosticHint' } },
         code = { 'Code', { fg = '#888888' } },
         text = { 'Text', { link = 'Normal' } },
      },
   },
}
function M.get_opts()
   return M._opts
end

function M.get_os_type()
   return M._os_type
end

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
   M._base_opts = opts
   M._opts = opts
   return opts
end

-- Load `<project_root>/.mql-compile.lua` for the given path, and merge it into the base opts
function M.load_project_config(path)
   local opts = M._base_opts
   path = vim.fn.fnamemodify(path, ':p')
   local root = vim.fs.root(path, opts.root_marker)
   if root then
      local project_config_path = vim.fs.joinpath(root, '.mql-compile.lua')
      if vim.fn.filereadable(project_config_path) == 1 then
         local ok, project_opts = pcall(dofile, project_config_path)
         if ok and type(project_opts) == 'table' then
            opts = M.deep_merge(M._base_opts, project_opts)
         else
            local msg = "Failed to load project config: '" .. project_config_path .. "'\n" .. tostring(project_opts)
            vim.notify(msg, vim.log.levels.ERROR, { title = 'mql-compile' })
         end
      end
   end
   M._opts = opts
   M.check_opts()
   return opts
end

function M.check_opts()
   -- Check deprecated opts
   if M._opts.rename.get_custom_path ~= nil then vim.schedule(function()
      vim.deprecate('`rename.get_custom_path` option', '`rename.to` option', 'v0.6.0', 'mql-compile.nvim', false)
   end) end
end

return M
