local M = {}

function M.get_path_separator()
   local sep = package.config:sub(1, 1) -- "/" or "\\"
   return sep
end

function M.file_exists(path)
   local file = io.open(path, 'r')
   if file ~= nil then
      io.close(file)
      return true
   else
      return false
   end
end

function M.convert_path_to_os(path, drive_letter, os_type)
   if os_type == 'macos' then return path:gsub('^' .. drive_letter, ''):gsub('\\', '/') end
end

function M.get_git_root()
   local git_root = vim.fn.system('git rev-parse --show-toplevel')
   git_root = string.gsub(git_root, '\n$', '')
   if vim.v.shell_error ~= 0 then return nil end
   return git_root
end

function M.get_root(path)
   local cwd = vim.fn.getcwd()
   local git_root = M.get_git_root(path)
   local current_buf_dir = vim.fn.expand('%:p:h')
   return git_root or cwd or current_buf_dir or path
end

function M.find_files_recursively(base_dir, pattern) -- pattern must be lua type
   local files = {}
   local uv = vim.loop

   local function scan_dir(dir)
      local handle = uv.fs_scandir(dir)
      if not handle then return end

      while true do
         local name, type = uv.fs_scandir_next(handle)
         if not name then break end

         local full_path = dir .. '/' .. name
         if type == 'directory' then
            scan_dir(full_path) -- 再帰的に探索
         elseif type == 'file' and name:match(pattern) then
            table.insert(files, full_path)
         end
      end
   end

   scan_dir(base_dir)
   return files
end

function M.get_relative_path(path)
   path = vim.fn.fnamemodify(path, ':.')
   return path
end

function M.get_absolute_path(path)
   path = vim.fn.fnamemodify(path, ':p')
   return path
end

function M.get_filename(path)
   path = vim.fn.fnamemodify(path, ':~')
   return path
end

function M.get_dir(path)
   path = vim.fn.fnamemodify(path, ':h')
   return path
end

function M.get_basename(path)
   path = vim.fn.fnamemodify(path, ':r')
   return path
end

function M.detect_file(path, filename)
   path = path or M.get_root()
   local find_cmd = 'find ' .. path .. ' -name ' .. filename
   local result = vim.fn.system(find_cmd)
   if result == nil or result == '' then return nil end
   find_list = M.split(result, '\n')
   if #find_list == 0 then
      return result
   else
      return find_list[1] -- just return first file
   end
end

-- Luaパターン -> Bashパターン
function M.pattern_lua_to_bash(lua_pattern)
   -- Luaの正規表現にある特殊文字を変換
   local bash_pattern = lua_pattern
      :gsub('%%.', '%%') -- `%` は Bash パターンのエスケープをそのまま維持
      :gsub('%.', '?') -- `.` は Bash パターンの `?` に対応
      :gsub('%%%*', '*') -- `%%*` は Bash の `*` に対応
      :gsub('%%%+', '*') -- Luaの`+` (1文字以上) は Bash の `*` (0文字以上)
      :gsub('%%%-', '-') -- `%%-` はそのまま `-` に
      :gsub('%%%(', '(') -- `%(` を `(` に
      :gsub('%%%)', ')') -- `%)` を `)` に
      :gsub('%%%[', '[') -- `%[` を `[` に
      :gsub('%%%]', ']') -- `%]` を `]` に
   return bash_pattern
end

-- Bashパターン -> Luaパターン
function M.pattern_bash_to_lua(bash_pattern)
   -- BashのワイルドカードをLuaパターンに変換
   local lua_pattern = bash_pattern
      :gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1') -- Lua用に特殊文字をエスケープ
      :gsub('%%%*', '.*') -- Bashの `*` を Luaの `.*` に
      :gsub('%%%?', '.') -- Bashの `?` を Luaの `.` に
   return lua_pattern
end

function M.get_extension_by_filename(filename, fallback_to_filename) -- もっと簡単に出来ない？
   fallback_to_filename = fallback_to_filename == nil or true
   local sep = M.get_path_separator()
   local extension = filename:match('%.(.*)$')
   if extension == nil and fallback_to_filename then extension = filename:match('^.+' .. sep .. '(.-)$') end
   return extension
end

return M
