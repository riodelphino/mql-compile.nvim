local M = {}

function M.in_table(tbl, value)
   for _, v in pairs(tbl) do
      if v == value then return true end
   end
   return false
end

function M.is_array(table)
   local is_array_flg = true
   for k, v in pairs(table) do
      if type(k) ~= 'number' or type(v) ~= 'string' then
         is_array_flg = false
         break
      end
   end
   return is_array_flg
end

function M.is_empty_table(t)
   return next(t) == nil -- next() returns nil if table = {}
end

function M.get_table_len(t)
   -- For arrays (integer indexes are sequential numbers)
   if #t > 0 then
      return #t
   else
      -- For associative arrays (keys other than integer)
      local count = 0
      for _ in pairs(t) do
         count = count + 1
      end
      return count
   end
end

-- Format table to string (ordered)
-- ex.) table to 'info: 1 | warning: 3 | error: 1'
function M.format_table_to_string(table, keys, key_value_separator, item_separator)
   key_value_separator = key_value_separator or ': '
   item_separator = item_separator or ' | '
   local str = ''
   for _, key in ipairs(keys) do
      if table[key] ~= nil then -- If the key exists
         local cur_str
         cur_str = key .. key_value_separator .. tostring(table[key]) .. item_separator
         str = str .. cur_str
      end
   end
   if str:match(item_separator .. '$') then str = str:gsub(item_separator .. '$', '') end -- Remove last item_separator
   return str
end

return M
