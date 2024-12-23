local M = {}

function M.setup()
    print("MQL Compiler plugin loaded!")
    -- 必要な初期化処理を記述
end

function M.compile_mql5(source_path)
   -- ex.) compile_mql5('/path/to/your/file.mq5')
   --
   -- Wine用のパスを設定
   local metaeditor_path = vim.fn.expand('~/Applications/Wineskin/MT5.app/drive_c/Program Files/MT5/MetaEditor64.exe')
   local win_log_path = source_path:gsub('%.mq5$', '.log')
   local mac_log_path = win_log_path:gsub('^Z:', ''):gsub('\\', '/')
   local quickfix_output = mac_log_path:gsub('%.log$', '.quickfix')

   -- コンパイル実行
   local compile_cmd = string.format('wine "%s" /compile:"%s" /log:"%s"', metaeditor_path, source_path, win_log_path)
   local compile_result = vim.fn.system(compile_cmd)

   -- コンパイル結果を確認
   if vim.v.shell_error == 0 then
      print('Compilation finished. Log saved to ' .. mac_log_path)
   else
      print('Compilation failed. Log saved to ' .. mac_log_path)
   end

   -- ファイルの文字エンコーディングを変換
   local convert_cmd = string.format('iconv -f UTF-16LE -t UTF-8 %s > %s.utf8 || iconv -f WINDOWS-1252 -t UTF-8 %s > %s.utf8 || cp %s %s.utf8', mac_log_path, mac_log_path, mac_log_path, mac_log_path, mac_log_path, mac_log_path)
   vim.fn.system(convert_cmd)

   -- ログファイルを読み込み、Quickfix形式に変換
   local log_file = io.open(mac_log_path .. '.utf8', 'r')
   local quickfix_lines = {}

   for line in log_file:lines() do
      -- エラー行だけを抽出
      if line:match(' : error') then
         local win_file, line_num, col_num, error_code, error_msg

         win_file, line_num, col_num, error_code, error_msg = line:match('^(.*)%((%d+),(%d+)%) : error (%d+): (.*)$')

         -- ファイル名をmacOS形式に変換
         local mac_file = win_file:gsub('^Z:', ''):gsub('\\', '/')

         -- Quickfix形式で出力（macOS形式のパスを使用）
         table.insert(quickfix_lines, string.format('%s:%s:%s: Error %s: %s', mac_file, line_num, col_num, error_code, error_msg))
      end
   end
   log_file:close()

   -- Quickfixファイルに保存
   local quickfix_file = io.open(quickfix_output, 'w')
   for _, line in ipairs(quickfix_lines) do
      quickfix_file:write(line .. '\n')
   end
   quickfix_file:close()

   -- 一時ファイルを削除
   os.remove(mac_log_path .. '.utf8')

   print('Quickfix file created: ' .. quickfix_output)

   -- NeovimでQuickfixを直接開く
   vim.cmd('cfile ' .. quickfix_output)
   vim.cmd('copen')
end


return M
