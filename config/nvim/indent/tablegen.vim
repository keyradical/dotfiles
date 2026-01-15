" Vim indent file
" Language:   TableGen
" Maintainer: The LLVM team
" Adapted from the LLVM/MLIR vim indent files
" What this indent plugin currently does:
"  - If no other rule matches copy indent from previous non-empty,
"    non-commented line.
"  - On '}' align the same as the line containing the matching '{'.
"  - If previous line starts with a block label, increase indentation.
"  - If the current line is a field definition that ends with '{' or '['
"    increase indentation.
" Stuff that would be nice to add:
"  - Continue comments on next line.
"  - If there is an opening+unclosed parenthesis on previous line indent to
"    that.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal shiftwidth=2 expandtab

setlocal indentkeys=0{,0},0[,0],<:>,!^F,o,O,e
setlocal indentexpr=GetTableGenIndent()

if exists("*GetTableGenIndent")
  finish
endif

function! FindOpenBrace(lnum)
  call cursor(a:lnum, 1)
  return searchpair('{', '', '}', 'bW')
endfun

function! GetTableGenIndent()
  " On '}' or ']' align the same as the line containing the matching '{' or '['
  let thisline = getline(v:lnum)
  if thisline =~ '^\s*[}\]]'
    call cursor(v:lnum, 1)
    silent normal %
    let opening_lnum = line('.')
    if opening_lnum != v:lnum
      return indent(opening_lnum)
    endif
  endif

  " Find a non-blank not-completely commented line above the current line.
  let prev_lnum = prevnonblank(v:lnum - 1)
  while prev_lnum > 0 && synIDattr(synID(prev_lnum, 1 + indent(prev_lnum), 0), "name") == "tgComment"
    let prev_lnum = prevnonblank(prev_lnum-1)
  endwhile
  " Hit the start of the file, use zero indent.
  if prev_lnum == 0
    return 0
  endif

  let ind = indent(prev_lnum)
  let prevline = getline(prev_lnum)

  " Add a 'shiftwidth' after lines that start a class, def, multiclass, or end
  " with an opening brace or bracket (for code blocks and list continuations)
  if prevline =~ '{\s*$' || prevline =~ '\[\s*$'
    let ind = ind + &shiftwidth
  endif

  " Add a 'shiftwidth' after class, def, defm, multiclass keywords if not
  " already followed by a brace on the same line
  if prevline =~ '^\s*\(class\|def\|defm\|multiclass\|let\|foreach\)\s\+' && prevline !~ '{\s*$'
    " Check if this is a continuation of a definition
    if thisline !~ '^\s*[:{]'
      let ind = ind + &shiftwidth
    endif
  endif

  return ind
endfunction
