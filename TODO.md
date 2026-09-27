# TODO


## IMPORTANT

- feat: Add `hooks.{pre|post}` options
   - [ ] Add `hooks` option as default
   - [ ] Add args to hooks.pre / hooks.post option (e.g. rename option has them)
   - [ ] Determin which args the hooks require
   - [ ] Run hooks in appropriate timings (e.g. `function run_hook(hook_name) ... end`)
   - [ ] Test them
   - [ ] Add default `hooks` option to README.md
- fix: Check `metaeditor.exe` existance before compile (Show error if not found)
- fix: Validate the compiling command before execution (ex. Check source file path / Pay attention to `cwd`)
- docs: Update demo movie

## OLD

- ❗️ rename.get_custom_path: Relative output path for the `*.mq5` `*.mq4`
- ❗️ Add `:MQLCompileRedo` command. (this might remove auto-detection?)
- `opts.information.actions` has other actions ?
   - Now only `compiling` & `including` are confirmed
- Show fugitive message on progress & success or error
- include path NOT WORKS for the space char in `Program Files`


> [!Tip]
> Use `vim.o.errorformat` ?
> - Easy to use, but not so customizable.
> - See [naoina/syntastic-MQL](https://github.com/naoina/syntastic-MQL/blob/master/syntax_checkers/mql5/metaeditor.vim)
> - If use it, counting functions should be changed.


