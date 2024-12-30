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

function M.pairs_to_string(counts, key_value_separator, item_separator)
   key_value_separator = key_value_separator or ': '
   item_separator = item_separator or ' | '
   local msg = ''
   for key, value in pairs(counts) do
      msg = msg .. key .. key_value_separator .. tostring(value) .. item_separator
   end
   if msg:match(item_separator .. '$') then -- remove last item_separator
      msg = msg:sub(1, -(#item_separator + 1))
   end
   return msg
end

return M
