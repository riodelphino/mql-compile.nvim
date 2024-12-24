local M = {}

local fn = require('mql_compiler.functions')
local opt = require('mql_compiler.options')
local cmd = require('mql_compiler.commands')

local _opts = {}
local _os_type = ''
local _mql = {}
local _loaded = false


function M.setup(opts)
   if _loaded then
      return
   end

   _loaded = true

   _os_type = fn.get_os_type()

   _opts = opt.merge(opts)

   cmd.create_commands()
end


return M
