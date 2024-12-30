local M = {}

local opt = require('mql_compile.options')
local fn = require('mql_compile.functions')
local cmd = require('mql_compile.commands')

local _loaded = false

function M.setup(user_opts)
   -- Check already loaded or not
   if _loaded then return end
   _loaded = true

   -- Initialize plugin
   opt._os_type = fn.get_os_type()
   opt._root = fn.get_root()
   opt._opts = opt.merge(user_opts)
   cmd.create_commands()
end

return M
