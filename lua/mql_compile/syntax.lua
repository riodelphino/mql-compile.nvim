local M = {}
-- FIXME: 途中！！！

-- Set qf's syntax
function M.set_qf_syntax()
   -- Clear syntax
   vim.cmd('syntax clear')

   -- Get highlight name by syntax_group
   local function get_hl_name(syntax_group)
      local hlgroups = require('mql_compile.options').get_opts().highlights.hlgroups
      local hlgroup = hlgroups[syntax_group]
      local hl_name, _ = unpack(hlgroup)
      return hl_name
   end

   -- Syntax rules
   local syntax = {
      -- Error code (num over 3digits)
      { 'match', 'code', [[/\d\+/]], {} },
      -- Filename
      { 'match', 'filename', [[/^[^|]*/]], { nextgroup = 'separator_left' } },
      -- Separator left
      { 'match', 'separator_left', [[/|/]], { nextgroup = 'line_nr' } },
      -- Error levels
      { 'match', 'error', [[/[Ee]rror /]], { nextgroup = 'code' } },
      { 'match', 'warning', [[/[Ww]arning /]], { nextgroup = 'code' } },
      { 'match', 'info', [[/[Ii]nfo/]], { nextgroup = 'separator_right' } },
      -- Separator Right
      { 'match', 'separator_right', [[/|/]], { nextgroup = 'text' } },
      -- Lnum, col
      { 'match', 'col', [[/col \d\+/]], {} },
   }

   -- Apply syntax rules
   for _, rule in ipairs(syntax) do
      local cmd_type, group, pattern, syn_opts = unpack(rule)
      syn_opts = syn_opts or {}

      local hl_name = get_hl_name(group)

      local cmd = string.format('syntax %s %s %s', cmd_type, hl_name, pattern)
      if syn_opts.nextgroup then cmd = cmd .. ' nextgroup=' .. syn_opts.nextgroup end

      vim.cmd(cmd)
   end

   vim.b.current_syntax = 'qf'
end

-- Execute if copen
vim.api.nvim_create_autocmd('FileType', {
   pattern = 'qf',
   callback = M.set_qf_syntax,
})

return M
