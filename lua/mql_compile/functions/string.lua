local M = {}

-- split a string
function M.split(str, delimiter)
   local result = {}
   local from = 1
   local delim_from, delim_to = string.find(str, delimiter, from, true)
   while delim_from do
      if delim_from ~= 1 then table.insert(result, string.sub(str, from, delim_from - 1)) end
      from = delim_to + 1
      delim_from, delim_to = string.find(str, delimiter, from, true)
   end
   if from <= #str then table.insert(result, string.sub(str, from)) end
   return result
end

return M
