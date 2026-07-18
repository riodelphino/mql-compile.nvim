-- test.lua:
--    Create dummy buffers so bufnr references are valid,
--    populate the quickfix list, and also show diagnostics
--    (virtual text / underline) in the buffer for visual context.
-- Usage:
--    :lua dofile(vim.fs.joinpath(vim.fn.getcwd(), 'test/test.lua'))

local bufs = {}
bufs[1] = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(bufs[1], '/tmp/qfpreview/dummy.lua')
vim.api.nvim_buf_set_lines(bufs[1], 0, -1, false, {
   'line 1',
   'line 2',
   'line 3',
   'line 4',
   'line 5',
   '// dummy content for repro',
})

local qflist = {
   { bufnr = bufs[1], col = 1, lnum = 1, text = 'Dammy Error 1', type = 'E', valid = 1 },
   { bufnr = 0, col = 1, lnum = 1, text = 'An error which is not binded to a buffer', type = 'E', valid = 1 }, -- bufnr=0 edge case
   { bufnr = bufs[1], col = 1, lnum = 3, text = 'Dammy Error 2', type = 'E', valid = 1 },
   { bufnr = bufs[1], col = 1, lnum = 4, text = 'Dammy Warning 1', type = 'W', valid = 1 },
   { bufnr = bufs[1], col = 1, lnum = 5, text = 'Dammy Infomation 1', type = 'I', valid = 1 },
}

vim.fn.setqflist(qflist)
vim.cmd('copen')

-- Convert qflist type ('E'/'W'/'I') to vim.diagnostic.severity
local severity_map = {
   E = vim.diagnostic.severity.ERROR,
   W = vim.diagnostic.severity.WARN,
   I = vim.diagnostic.severity.INFO,
}

local ns = vim.api.nvim_create_namespace('qfpreview_repro')
local diagnostics = {}
for _, item in ipairs(qflist) do
   if item.bufnr ~= 0 then -- Skip bufnr=0
      table.insert(diagnostics, {
         bufnr = item.bufnr,
         lnum = item.lnum - 1, -- 1-indexed -> 0-indexed
         col = item.col - 1,
         message = item.text,
         severity = severity_map[item.type] or vim.diagnostic.severity.HINT,
      })
   end
end

vim.diagnostic.set(ns, bufs[1], diagnostics)
