# wine_and_metaeditor

> [!Important]
> This note contains technical information about wine & metaeditor commands.


## Command usage

> [!Note]
> Basics about commands


### wine

`wine --help` shows:
```txt
Usage: wine PROGRAM [ARGUMENTS...]   Run the specified program
       wine --help                   Display this help and exit
       wine --version                Output version information and exit
```

### metaeditor

> [!Note]
> Command usages are same at all with MT5 and MT4.

metaeditor's `/help` shows:

`MetaEditor64.exe` of MT5
```txt
Usage:
   MetaEditor64.exe /compile:"path" [/include:"path"] [/project] [/log] [/s]
   
Args:
   /compile:"path" - source file, folder or project file path
   /project        - compile project file
   /include:"path" - path to MOL4|MOL5 Folder
   /log            - create compilation log file
   /s              - check a program syntax without compilation

```
`metaeditor.exe` of MT4
```txt
Usage;
   metaeditor.exe /compile:"path" [/include:"path"] [/project] [/log] [/s]

Args:
   /compile:"path" - source file, folder or project file path
   /project        - compile project file
   /include:"path" - path to MOL4\MoL5 folder
   /log            - create compilation log file
   /s              - check a program syntax without compilation
```



## Handling paths

`MacOS <--> wine <--> MT5/MT4` is a special environment for metaeditor.  
So need to consider about conversion in paths.


### At first

**Conclusion:**
- `cwd` on project root
- Absolute path in specifying `metatrader's exe`.  
- Relative path in specifying `/compile:` and `/log:`.  
- All paths can be written in Linux/MacOS path.

This is easier & safer & ensured.  

Examples:
| Type              | Recommend               | Example                                                                                  |
| ----------------- | ----------------------- | ---------------------------------------------------------------------------------------- |
| metatrader's path | Absolute on Linux/MacOS | /Users/username/Applications/Wineskin/MT5.app/drive_c/Program Files/MT5/MetaEditor64.exe |
| /compile:         | Relative on Linux/MacOS | ea.mq5                                                                                   |
| /log:             | Relative on Linux/MacOS | ea.log                                                                                   |
| /include:         | ???                     | ??? (not sure about hadling spaces like ".../Program Files/...")                         |

`ea.mq5` is located in `/Users/username/Projects/EA/myea/ea.mq5`, so cwd is set to `/Users/username/Projects/EA/myea`


I will show you the way of why I came to think as above.


### lua's path handling

Apparently the lua works with either `/` or `\\` as dir separator.  
But it depends on the command tool to recognize `/` or not.  
So \\ is safer.


### wine's auto conversion

I guess, the `wine` command automatically/flexibly converts paths in its args, between Linux/MacOS and Windows.

So, if Linux or MacOS paths are specified, they are automatically/flexibly converted to Windows paths internally.

`wine` command converts:
| Type          | Linux/MacOS path | <--> | Windows path         |
| ------------- | ---------------- | :--: | -------------------- |
| Absolute path | /path/to/ea.mq5  | <--> | Z:\\path\\to\\ea.mq5 |
| Relative path | path/to/ea.mq5   | <--> | path\\to\\ea.mq5     |

(Relative paths need `cwd` is set correctly.)

> [!Warning]
> But it's not perfect, and has some problems.


### On absolute paths

> [!Warning]
> `#include` not works

If you use absolute path in `/compile:` , like `/compile:"/path/to/ea.mq5"`, metatrader converts `#include` path incorrectly(the first `/` is removed somewhy) and compiling fails. See below table.

`/compile:` arg:
| Type          | Linux/MacOS path         | --> | Windows path     | Result                            |
| ------------- | ------------------------ | :-: | ---------------- | --------------------------------- |
| Absolute path | /compile:"/path/to/ea.mq5" | --> | path\\to\\ea.mq5 | Failed compiling (file not found) |
| Relative path | /compile:"path/to/ea.mq5"  | --> | path\\to\\ea.mq5 | Succeeded compiling               |

### On relative paths

> [!Note]
> Need to set `cwd`

> [!Note]
> Specifying all in relative paths is difficult.

When using relative paths, `cwd` must be set correctly.

If `cwd` is set on the mq5/mq4 project root, the metatrader exe is out of the cwd.  
You have to use `../` many times and dig again deeper.  
Similarly, `cwd` on metatrader's path cause same difficulty in specifying mq5/mq4 file.
It's difficult to set all as relatively.

So, `one is absolute and others are relative`, is easier.


### Conclusion

> [!Note]
> This is the best way.

Thus, using an absolute path for MetaTrader and relative paths for others is the best approach.

### Additional info


#### Quotation

In terminal, the paths including spaces have to be quoted:
```bash
wine "/Users/username/Applications/Wineskin/MT5.app/drive_c/Program Files/MT5/MetaEditor64.exe" # OK
wine /Users/username/Applications/Wineskin/MT5.app/drive_c/Program Files/MT5/MetaEditor64.exe # Error
```
But `vim.system` or `vim.fn.cmd` or `job(plenary's async)` do not need quotations, I think.


#### The table of path types tested

Tested path type on MacOS:
| OS type |    Path type    | metaeditor exe | /compile: | /log: | Example                                                 | Checked |
| ------- | :-------------: | :------------: | :-------: | :---: | :------------------------------------------------------ | :-----: |
| MacOS   |        ~        |                |           |       | '~/Projects/myea/ea.mq5'                                |    ✔    |
| MacOS   |   ./ relative   |       △        |    △!     |  △!   | 'myea/ea.mq5'                                           |    ✔    |
| MacOS   |   / absolute    |       o!       |           |   o   | '/Users/username/Projects/myea/ea.mq5'                  |    ✔    |
| Windows | .\\\\ relative  |       △        |     △     |   △   | 'myea\\\\ea.mq5' / 'ea.mq5'                             |    ✔    |
| Windows | X:\\\\ absolute |       o        |     o     |   o   | 'Z:\\\\Users\\\\username\\\\Projects\\\\myea\\\\ea.mq5' |    ✔    |

  ... NOT WORKS  
△ ... WORKS WITH CWD (on it's dir)  
o ... WORKS  
o! / △! ... Finally chosen  


## Unresolved issues

 > [!Warning]
 > `/include:` not accepts spaces ...

`/include:` does not accept the paths with spaces like `.../Profram Files/...`, maybe internally.  
Why?





