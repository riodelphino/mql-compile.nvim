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

-- Format table to string (ordered)
function M.format_table_to_string(table, keys, key_value_separator, item_separator)
   key_value_separator = key_value_separator or ': '
   item_separator = item_separator or ' | '
   local str = ''
   for i, key in ipairs(keys) do
      if table[key] ~= nil then -- If the key exists
         local cur_str
         if i == #keys then -- If last item
            cur_str = key .. key_value_separator .. tostring(table[key])
         else
            cur_str = key .. key_value_separator .. tostring(table[key]) .. item_separator
         end
         str = str .. cur_str
      end
   end
   return str
end

return M
