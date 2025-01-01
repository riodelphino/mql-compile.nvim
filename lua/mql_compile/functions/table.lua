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

function M.table_to_string(table, keys, key_value_separator, item_separator)
   key_value_separator = key_value_separator or ': '
   item_separator = item_separator or ' | '
   local str = ''
   for _, key in ipairs(keys) do
      str = str .. key .. key_value_separator .. tostring(table[key]) .. item_separator
   end
   if str:match(item_separator .. '$') then -- remove last item_separator
      str = str:sub(1, -(#item_separator + 1))
   end
   return str
end

return M
