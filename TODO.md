# TODO


## IMPORTANT

- [ ] feat: Load per-project option lua file
- [ ] feat: Choose compile target from list

## OLD

- [ ] ❗️ rename.get_custom_path: Relative output path for the `*.mq5` `*.mq4`
- [ ] ❗️ Customizable for each project by `mqlcompile.yaml`
- [ ] ❗️ Add `:MQLCompileRedo` command. (this might remove auto-detection?)
- [ ] `opts.information.actions` has other actions ?
   - [ ] Now only `compiling` & `including` are confirmed
- [ ] git
   - [x] Detect git root
   - [ ] Prompt for listing up files by `vim.ui.select`.
   - [ ] If only one mql5 on git root, compile without prompt
- [ ] Show fugitive message on progress & success or error
- [ ] include path NOT WORKS for the space char in `Program Files`


> [!Tip]
> Use `vim.o.errorformat` ?
> - Easy to use, but not so customizable.
> - See [naoina/syntastic-MQL](https://github.com/naoina/syntastic-MQL/blob/master/syntax_checkers/mql5/metaeditor.vim)
> - If use it, counting functions should be changed.


