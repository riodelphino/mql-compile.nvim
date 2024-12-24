local M = {}

function M.file_exists(path)
   local file=io.open(path,"r")
   if file ~= nil then
      io.close(file)
      return true
   else
      return false
   end
end

function M.get_os_type()
    if vim.fn.has('win32') == 1 then
        return 'windows'
    elseif vim.fn.has('macunix') == 1 then
        return 'macos'
    else
        return 'linux'
    end
end



return M

