local M = {}

function M.set_highlights()
   local opt = require('mql_compile.options')
   local opts = opt.get_opts()

   if not opts.highlights.enabled then return end

   local hlgroups = opts.highlights.hlgroups
   for _, hlgroup in pairs(hlgroups) do
      hl_name, hl_opts = unpack(hlgroup)
      vim.api.nvim_set_hl(0, hl_name, hl_opts)
   end
end

return M
