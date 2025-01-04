local M = {}

function M.set_highlights()
   local opt = require('mql_compile.options')
   local opts = opt.get_opts()

   if not opts.highlights.enabled then return end

   local hlgroups = opts.highlights.hlgroups
   for _, hl in pairs(hlgroups) do
      vim.api.nvim_set_hl(0, hl.name, hl.opts)
   end
end

return M
