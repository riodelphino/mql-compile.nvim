local M = {}

local opt = require('mql_compile.options')
local fn = require('mql_compile.functions')
local cmd = require('mql_compile.commands')
local hl = require('mql_compile.highlights')
local syn = require('mql_compile.syntax')

local _loaded = false

function M.setup(user_opts)
   -- Check already loaded or not
   if _loaded then return end
   _loaded = true

   -- Initialize plugin
   opt._os_type = fn.get_os_type()
   opt._opts = opt.merge(user_opts)
   opt._opts = opt.merge_project_config()
   cmd.create_commands()
   syn.set_qf_syntax()
   hl.set_highlights()
end

return M
