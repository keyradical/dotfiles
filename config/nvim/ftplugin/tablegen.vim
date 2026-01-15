" Vim filetype plugin file
" Language: TableGen
" Maintainer: The LLVM team

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

setlocal softtabstop=2 shiftwidth=2
setlocal expandtab
setlocal comments+=://
setlocal commentstring=//\ %s
" TableGen identifiers can include alphanumeric, underscore
setlocal iskeyword=@,48-57,_
