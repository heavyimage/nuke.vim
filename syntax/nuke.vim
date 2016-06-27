" Vim syntax file
" Language:     nuke Scripts
" Filenames:    *.nk
" " Maintainer: Jesse Spielman <jesse.spielman@gmail.com>
" URL:          http://www.github.com/heavyimage/nuke.vim
" Last Change:  2016 June 27 - Initial Version

" for colors: :so $VIMRUNTIME/syntax/hitest.vim

if exists("b:current_syntax")
  finish
endif

" Top level stuff
" Comments
syn region  nukeComment		start="^\s*\#" skip="\\$" end="$"
syn region  nukeComment		start=/;\s*\#/hs=s+1 skip="\\$" end="$"

" Nuke Version
syn match nukeVersion "^version\ \d\+\.\d\+ v\d\+$"

" Node matching
syn region nukeNode fold transparent matchgroup=nukeNodeOuters start="^[a-zA-Z0-9_]\+ {" skip="\<" end="}$" contains=ALL

" layout  matching
syn region nukeLayout fold start="^define_window_layout_xml {" skip="\<\"" end="^}$" contains=None

syn region nukeLayerGuts matchgroup=nukeLayerOuters start="^add_layer {" end="}$"

" Stack /group commands
syn match nukeStackSet "^set [a-zA-Z0-9]\+ \[stack \d\+\]$"
syn match nukeStackPush "^push \$\?[a-zA-Z0-9]\+$"
syn match nukeGroupEnd "^end_group$"

" Do most things dynamically but at least make name a keyword for easy browsing
syn keyword nodeName name contained

" Within nodes
" Knob name matching
syn match nukeKnobName "^[a-zA-Z0-9_]\+ " contained

" Knob value matching
syn match nukeName "[a-zA-Z\_0-9]\+$" contained
syn match nukeIntVal "\-\?[0-9]\+$" contained
syn match nukeFloatVal "\-\?[0-9\.]\+$" contained
syn region nukeExpressionVal start="{" end="}" contained contains=nukeExpressionVal
syn region nukeQuotedStringVal start=/"/ skip=/\\./ end=/"$/ contained
syn match nukeTimecodeVal "[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}$" contained
syn match nukePathVal "[\/a-zA-Z0-9\-\_\%\.\#]\+\.[a-zA-Z0-9]\{2,5\}$" contained
syn match nukeBoolVal "\(true\|false\)$" contained
syn match nukeIntVal "\-\?[0-9\.]\+\-\-\?[0-9\.]\+$" contained

" Colors
" Top level stuff
hi link nukeBraceEncl MatchParen
hi link nukeComment Comment
hi link nukeVersion PreProc
hi link nukeLayout PreProc

" Stack operations
hi link nukeStackSet PreProc
hi link nukeStackPush PreProc
hi link nukeGroupEnd PreProc

" Nodes
hi link nukeNodeOuters Function
hi link nukeLayerOuters Function

" Knob names
hi link nukeKnobName Statement
hi link nukeLayerGuts Statement

" Knob values
" TODO: Define different colors for each type
" required improved regexes though...
hi link nodeName type
hi link nukeExpressionVal Special
hi link nukeQuotedStringVal Special
hi link nukeIntVal Special
hi link nukeFloatVal Special
hi link nukePathVal Constant
hi link nukeTimecodeVal Special
hi link nukeName Special
hi link nukeBoolVal Special
" Scripts can be long -- go back a ways
syntax sync minlines=500

let b:current_syntax = "nuke"


