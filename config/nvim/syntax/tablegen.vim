" Vim syntax file
" Language:   TableGen
" Maintainer: The LLVM team, http://llvm.org/
" Version:    $Revision$
" Some parts adapted from the MLIR vim syntax file.

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case match

" Types
syn keyword tgType bit bits code dag int list string

" Keywords
syn keyword tgKeyword
      \ assert
      \ class
      \ code
      \ dag
      \ def
      \ defm
      \ defset
      \ defvar
      \ dump
      \ else
      \ field
      \ foreach
      \ if
      \ in
      \ include
      \ let
      \ multiclass
      \ then

" Operators
syn keyword tgOperator
      \ bang
      \ cond
      \ concat
      \ dag
      \ empty
      \ eq
      \ exists
      \ filter
      \ find
      \ foldl
      \ foreach
      \ ge
      \ getdagop
      \ getop
      \ gt
      \ head
      \ if
      \ interleave
      \ isa
      \ le
      \ listconcat
      \ listsplat
      \ lt
      \ ne
      \ range
      \ setdagop
      \ setop
      \ shl
      \ size
      \ sra
      \ srl
      \ strconcat
      \ sub
      \ substr
      \ subst
      \ tail
      \ tolower
      \ toupper
      \ xor

" Special values
syn keyword tgBoolean true false
syn keyword tgSpecial ?

" Numbers
syn match tgNumber /\<\d\+\>/
syn match tgNumber /\<0x\x\+\>/
syn match tgNumber /\<0b[01]\+\>/

" Strings and code blocks
syn region tgString start=/"/ skip=/\\"/ end=/"/
syn region tgCode start=/\[{/ end=/}\]/

" Spell checking is enabled only in comments by default
syn match tgComment /\/\/.*$/ contains=@Spell

" Preprocessor
syn match tgPreProc /#.*$/

" Template arguments
syn match tgTemplateArg /<[^>]*>/

" Syntax-highlight lit test commands and bug numbers (similar to MLIR)
" These must come AFTER the regular comment pattern
syn match tgSpecialComment /\/\/\s*RUN:.*$/
syn match tgSpecialComment /\/\/\s*CHECK:.*$/
syn match tgSpecialComment "\v\/\/\s*CHECK-(NEXT|NOT|DAG|SAME|LABEL):.*$"
syn match tgSpecialComment /\/\/\s*expected-error.*$/
syn match tgSpecialComment /\/\/\s*expected-remark.*$/
syn match tgSpecialComment /\/\/\s*REQUIRES:.*$/

if version >= 508 || !exists("did_c_syn_inits")
  if version < 508
    let did_c_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink tgType Type
  HiLink tgKeyword Keyword
  HiLink tgOperator Operator
  HiLink tgBoolean Boolean
  HiLink tgSpecial Special
  HiLink tgNumber Number
  HiLink tgString String
  HiLink tgCode String
  HiLink tgComment Comment
  HiLink tgSpecialComment SpecialComment
  HiLink tgPreProc PreProc
  HiLink tgTemplateArg Type

  delcommand HiLink
endif

let b:current_syntax = "tablegen"
