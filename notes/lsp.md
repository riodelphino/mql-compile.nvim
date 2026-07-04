# LSP

**Recommend**: [clangd](https://github.com/clangd/clangd)


## Install clangd

Can install via Mason.
`:MasonInstall clangd`


## Configure clangd

Save below code as `.clangd` in your project root, or as `~/Library/Preferences/clangd/config.yaml`:

for MQL5:
```yaml
# Common settings
CompileFlags:
  Add: [-xc++, -std=c++17]
---
# MQL5 settings
If:
  PathMatch: [.*\.mq5, .*\.mqh]
CompileFlags:
  Add:
    - -DMQL5
    - -ferror-limit=0 # Continue parsing even if too many MQL syntax errors
    - "-I/Users/<username>/Applications/MetaTrader 5.app/Contents/SharedSupport/prefix/drive_c/Program Files/MetaTrader 5/MQL5/Include" # Include MQL5 lib
Diagnostics:
  Suppress: # Suppress fake errors/warnings
    - pp_invalid_directive
    - unknown_typename
    - pp_file_not_found
    - undeclared_var_use
    - typecheck_member_reference_suggestion
    - member_function_call_bad_type
  ClangTidy:
    Remove: # Remove fake errors/warningns
      - readability-magic-numbers
```

for MQL4:
```yaml
# Common settings
CompileFlags:
  Add: [-xc++, -std=c++17]
---
# MQL4 settings
If:
  PathMatch: [.*\.mq4, .*\.mqh]
CompileFlags:
  Add:
    - -DMQL4
    - -ferror-limit=0 # Continue parsing even if too many MQL syntax errors
    - "-I/Users/<username>/Applications/MetaTrader 4.app/Contents/SharedSupport/prefix/drive_c/Program Files/MetaTrader 4/MQL4/Include" # Include MQL4 lib
Diagnostics:
  Suppress: # Suppress fake errors/warnings
    - pp_invalid_directive
    - unknown_typename
    - pp_file_not_found
    - undeclared_var_use
    - typecheck_member_reference_suggestion
    - member_function_call_bad_type
  ClangTidy:
    Remove: # Remove fake errors/warningns
      - readability-magic-numbers
```

> [!warning]
> Ensure to:
> - Replace `<username>` to your actual username in `"-I/..."` config.
> - Replace the path to the actual MT5 installed path in `"-I/..."` config.

