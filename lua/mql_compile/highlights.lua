local M = {}

function M.set_highlights()
   local opt = require('mql_compile.options')
   local opts = opt.get_opts()

   if not opts.highlights.enabled then return end
   local hl_prefix = opts.higlights.hl_prefix

   local hl_groups = opts.highlights.hl_groups
   for _, hl_group in pairs(hl_groups) do
      hl_name, hl_opts = unpack(hl_group)
      vim.api.nvim_set_hl(0, hl_prefix .. hl_name, hl_opts)
   end
end

return M
