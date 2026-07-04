# Format

**Recommend**: clangd-format


## Install clang-format

It's included in clangd as a lib, but can be installed separatedlly.

via Mason:
`:MasonInstall clangd-format`


## Configure clang-format

Save below code as `.clang-format` in your project root:

for MQL5:
```yaml
Language: Cpp
SortIncludes: false
ColumnLimit: 0
IndentWidth: 3
UseTab: Never
ContinuationIndentWidth: 3
AlignConsecutiveAssignments:
  Enabled: true
  AcrossEmptyLines: false
  AcrossComments: true
  AlignCompound: true
  PadOperators: true
AllowShortCaseLabelsOnASingleLine: true
AlignConsecutiveShortCaseStatements:
  Enabled: true
  AcrossEmptyLines: false
  AcrossComments: true
  AlignCaseColons: false
IndentCaseLabels: true
AlignTrailingComments: true
```

for MQL4:
```yaml
Language: C
...
(Same with above MQL5 settings)
```

Then, add settings to `conform.nvim` config.
```lua
require('conform').setup({
   ...
   formatters_by_ft = {
      mql5 = { 'clang-format' },
      mql4 = { 'clang-format' },
   },
   ...
})

```

