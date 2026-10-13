---@meta

---@class mql_compile.Ctx
---@field root string      Abs path of project root
---@field project string   Project name (= basename of root, e.g. 'myproject')
---@field ft string        Filetype ('mql5' | 'mql4')
---@field src_path string  Source file path (relative to cwd)
---@field dir string       Parent dir of the source file
---@field base string      Basename with source ext (e.g. 'myea.mq5')
---@field fname string     Filename without ext (e.g. 'myea')
---@field ext string       Compiled ext (e.g. 'ex5')
---@field ext_src string   Source ext (e.g. 'mq5')
---@field ver string?      '#property version' value (e.g. '1.10' or nil)
---@field major string?    Major version (e.g. '1')
---@field minor string?    Minor version (e.g. '10')
---@field dest_path string? Abs path of the compiled file finally placed (Not set in `rename.to`)

---@class mql_compile.ResultCtx : mql_compile.Ctx
---@field dest_path string Abs path of the compiled file finally placed
---@field ok boolean       true if no errors
---@field counts table     Counts of each quickfix type (e.g. { error = 1, warning = 2 })

---@deprecated Use `mql_compile.Ctx` instead
---@alias mql_compile.RenameCtx mql_compile.Ctx
