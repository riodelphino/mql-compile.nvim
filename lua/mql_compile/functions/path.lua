local M = {}

local opt = require('mql_compile.options')

local sep

function M.get_path_separator()
   local separator = package.config:sub(1, 1) -- "/" or "\\"
   return separator
end

function M.file_exists(path)
   -- local f = io.open(path, 'r')
   -- if f then io.close(f) end
   -- return f ~= nil
   if vim.fn.filereadable(path) == 0 then return false end
   return true
end

function M.folder_exists(path)
   if vim.fn.isdirectory(path) == 0 then return false end
   return true
end

-- NOTE: Don't need anymore, but may use on converting information
-- function M.convert_path_to_os(path, drive_letter, os_type)
--    if os_type == 'macos' then return path:gsub('^' .. drive_letter, ''):gsub('\\', '/') end
-- end

function M.get_root(path)
   path = path or vim.fn.getcwd()
   local opts = opt.get_opts()
   local root = vim.fs.root(path, opts.root_marker)
   return root
end

function M.find_source_files(path, bash_patterns)
   local lua_patterns = {}
   for i, pattern in ipairs(bash_patterns) do
      lua_patterns[i] = M.pattern_bash_to_lua(pattern)
   end

   return vim.fs.find(function(name, _)
      for _, lua_pattern in ipairs(lua_patterns) do
         if name:match(lua_pattern) then return true end
      end
      return false
   end, {
      path = path,
      type = 'file',
      follow = false, -- Not follow symlink dir
      limit = math.huge,
   })
end

-- function M.find_files_recursively(base_dir, pattern) -- pattern must be lua type
--    local files = {}
--    local uv = vim.loop
--
--    local function scan_dir(dir)
--       local handle = uv.fs_scandir(dir)
--       if not handle then return end
--
--       while true do
--          local name, type = uv.fs_scandir_next(handle)
--          if not name then break end
--
--          local full_path = dir .. '/' .. name
--          if type == 'directory' then
--             scan_dir(full_path) -- Recursivelly
--          elseif type == 'file' and name:match(pattern) then
--             table.insert(files, full_path)
--          end
--       end
--    end
--
--    scan_dir(base_dir)
--    return files
-- end

function M.get_relative_path(path)
   path = vim.fn.fnamemodify(path, ':.')
   return path
end

function M.get_absolute_path(path)
   path = vim.fn.fnamemodify(path, ':p')
   return path
end

function M.get_filename(path)
   path = vim.fn.fnamemodify(path, ':t:r')
   return path
end

function M.get_dir(path)
   path = vim.fn.fnamemodify(path, ':h')
   return path
end

function M.get_basename(path)
   path = vim.fn.fnamemodify(path, ':t')
   return path
end

function M.get_extension(path)
   path = vim.fn.fnamemodify(path, ':e')
   return path
end

function M.to_windows_path(path)
   return path:gsub('/', '\\')
end

function M.to_unix_path(path)
   return path:gsub('\\', '/')
end

function M.split_path(path)
   local dir = M.get_dir(path)
   local base = M.get_basename(path)
   local fname = M.get_filename(path)
   local ext = M.get_extension(path)
   return dir, base, fname, ext
end

function M.get_compiled_path(source_path)
   local dir, _, fname, _ = M.split_path(source_path)
   local compiled_ext = M.get_compiled_extension(source_path)
   if compiled_ext == nil then return nil end
   local compiled_path = vim.fs.joinpath(dir, fname .. '.' .. compiled_ext)
   return compiled_path
end

function M.get_compiled_extension(source_path)
   local ext = M.get_extension(source_path)
   local compiled_ext
   local opts = require('mql_compile.options').get_opts()
   for _, mql in pairs(opts.ft) do
      if ext == mql.extension.source then
         compiled_ext = mql.extension.compiled
         break
      end
   end
   return compiled_ext
end

function M.get_filetype(path)
   local opts = require('mql_compile.options').get_opts()
   local ext = M.get_extension(path)
   for ft_name, ft in pairs(opts.ft) do
      if ext == ft.extension.source then return ft_name end
   end
   return nil
end

---@param bash_pattern string
---@return string lua_pattern
function M.pattern_bash_to_lua(bash_pattern)
   local lua_pattern = bash_pattern
      :gsub('([%^%$%(%)%%%.%[%]%+%-])', '%%%1') -- Escape lua special strings (except * ?)
      :gsub('%*', '.*') -- bash * -> lua .*
      :gsub('%?', '.') -- bash ? -> lua .
   return lua_pattern
end

sep = M.get_path_separator()

return M
