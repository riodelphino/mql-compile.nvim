" if exists('b:current_syntax')
"    finish
" endif
" 
" 
" " syn match qfFileName /^[^│]+/ nextgroup=qfSeparatorLeft
" " syn match qfSeparatorLeft /│/ contained nextgroup=qfLineNr
" " syn match qfLineNr /\d\scol\s\d/ contained nextgroup=qfSeparatorRight
" " syn match qfSeparatorRight '│' contained nextgroup=qfError,qfWarning,qfInfo,qfNote
" " syn match qfError /\s[Ee]rror:.*$/ contained
" " syn match qfWarning /\s[Ww]arning:.*$/ contained
" " syn match qfInfo /\s[Ii]nformation:.*$/ contained
" " syn match qfNote /\s[Nn]ote:.*$/ contained
" " syn match qfNote /\s[Hh]ing:.*$/ contained
" " 
" " hi def link qfFileName Directory
" " hi def link qfSeparatorLeft Delimiter
" " hi def link qfSeparatorRight Delimiter
" " hi def link qfLineNr LineNr
" " hi def link qfError DiagnosticError
" " hi def link qfWarning DiagnosticWarn
" " hi def link qfInfo DiagnosticInfo
" " hi def link qfNote DiagnosticHint
" 
" 
" 
" " ~/.config/nvim/syntax/qr.vim
" syntax clear
" 
" " ファイル名部分
" syn match qfFileName /^[^│]+/
" 
" " " 区切りの "│" マーク
" " syn match qfSeparatorLeft /│/ contained nextgroup=qfLineNr
" " 
" " " 行番号と列番号の部分
" " syn match qfLineNr /\d\+\scol\s\d\+/ contained nextgroup=qfSeparatorRight
" " 
" " " 区切りの "│" マーク (2つ目)
" " syn match qfSeparatorRight /│/ contained nextgroup=qfMessage
" " 
" " " メッセージ部分
" " syn match qfMessage /\s[Ee]rror:\d/ contained
" " syn match qfWarning /\s[Ww]arning:\d/ contained
" " syn match qfInfo /\s[Ii]nfo:\d/ contained
" " syn match qfNote /\s[Nn]ote:\d/ contained
" 
" let b:current_syntax = 'qf'
" 
" 
" " うーん
" " syntax match QfError /\<error:\>/ containedin=ALL
" " syntax match QfWarn /\<warning:\>/ containedin=ALL
" " 
" " highlight link QfError DiagnosticError
" " highlight link QfWarn DiagnosticWarn
" " highlight link QfInfo DiagnosticInfo
" " highlight link QfHint DiagnosticHint
" " 
" " set errorformat=%f:%l:%c:\ %t%*[^:]:%n:\ %m
" " " vim.o.errorformat = "%f:%l:%c: %t%*[^:]:%n: %m"



if exists('b:current_syntax')
   finish
endif

" *.qf format
" ea.mq4:18:1: error:161: 'aaa' - unexpected end of program
" ea.mq4:18:1: error:149: 'aaa' - unexpected token, probably type is missing?
" ea.mq4:11:11: warning:31: variable 'test' not used

" nvim's quickfix display
" ea.mq4|18 col 1| error:161: 'aaa' - unexpected end of program
" ea.mq4|18 col 1| error:149: 'aaa' - unexpected token, probably type is missing?

" そのあとに 閉じて開くとこれ


" syn match qfFileName /^[^│]*/ nextgroup=qfSeparatorLeft
" syn match qfSeparatorLeft /│/ contained nextgroup=qfLineNr
" syn match qfLineNr /\d+:\d+ */ contained nextgroup=qfType
" syn match qfType /[^\d]* -- むり
" syn match qfSeparatorRight /│/ contained nextgroup=qfError,qfWarning,qfInfo,qfHint,qfNote
" 
" syn match qfError / E .*$/ contained
" syn match qfWarning / W .*$/ contained
" syn match qfInfo / I .*$/ contained
" syn match qfNote / [NH] .*$/ contained

" syn match qfError / *error:\d:/ nextgroup=qfMsg
" syn match qfWarning / *warning:\d:/ nextgroup=qfMsg
" syn match qfInfo / *information:\d:/ nextgroup=qfMsg
" syn match qfHint / *hint:\d:/ nextgroup=qfMsg
" syn match qfNote / *note:\d:/ nextgroup=qfMsg
" syn match qfMsg / *.*$/

" syn match qfError /\s*error:\d+:/ contained nextgroup=qfMsg
" syn match qfWarning /\s*warning:\d+:/ contained nextgroup=qfMsg
" syn match qfInfo /\s*information:\d+:/ contained nextgroup=qfMsg
" syn match qfHint /\s*hint:\d+:/ contained nextgroup=qfMsg
" syn match qfNote /\s*note:\d+:/ contained nextgroup=qfMsg
" syn match qfMsg /\s.*$/ contained

" " syn match qfFileName /^[^│]*/
" syn match qfFileName /^[^|]*/
" 
" syn match qfError /[Ee]rror/
" syn match qfwarning /[Ww]arning/
" syn match qfInfo /[Ii]nfo/
" syn match qfInfo /[Ii]nformation/
" syn match qfHint /[Hh]int/
" syn match qfNote /[Nn]ote/
" 
" 
"hi def link qfFileName Directory
"hi def link qfSeparatorLeft Delimiter
"hi def link qfSeparatorRight Delimiter
"hi def link qfLineNr LineNr
"hi def link qfError DiagnosticError
"hi def link qfWarning DiagnosticWarn
"hi def link qfInfo DiagnosticInfo
"hi def link qfInformation DiagnosticInfo
"hi def link qfHint DiagnosticHint
"hi def link qfNote DiagnosticHint
"hi def link qfMsg Normal
"hi def link qfCode DiagnosticInfo " 仮

" Sample
" ea.mq4|1 col 1 info| compiling 'ea.mq4'
" mq4.mqh|1 col 1 info| including 'mq4.mqh'
" ea.mq4|18 col 1 error 161| 'aaa' - unexpected end of program
" ea.mq4|18 col 1 error 149| 'aaa' - unexpected token, probably type is missing?
" ea.mq4|11 col 11 warning  31| variable 'test' not used

" エラーコード部分のハイライト（3桁以上の数字）
syn match qfCode /\d\+/  " エラーコード部分のハイライト
" ファイル名のハイライト
syn match qfFileName /^[^|]*/ nextgroup=qfSeparatorLeft " ファイル名部分（|で区切られる最初の部分）
syn match qfSeparatorLeft /|/ nextgroup=qfLineNr
" エラーレベル（info, error, warning）をハイライト
syn match qfError /[Ee]rror / nextgroup=qfCode " エラー行のハイライト
syn match qfWarning /[Ww]arning / nextgroup=qfCode  " 警告行のハイライト
syn match qfInfo /[Ii]nfo/ nextgroup=qfSeparatorRight " info 行のハイライト
syn match qfSeparatorRight /|/ nextgroup=qfText

" 残りのテキスト部分をハイライト
" syn match qfText /\v\|.*$/  " |以降のテキストをハイライト

" 行番号・列番号の部分もハイライト
syn match qfCol /col \d\+/  " col 1 のような形式をハイライト

let b:current_syntax = 'qf'

