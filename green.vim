" A green colorscheme

" Maintainer:  https://github.com/julien
" Last Change: 2022/09/21

highlight clear

if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "green"

hi ColorColumn ctermbg=40 guibg=green
hi Comment ctermfg=2 guifg=yellowgreen
hi Constant ctermfg=40 guifg=green
hi CursorLine term=none cterm=none gui=none
hi Directory ctermfg=40 guifg=green
hi Folded ctermbg=40 guibg=yellowgreen ctermfg=0 guifg=gray10
hi Identifier ctermfg=40 guifg=green
hi LineNr ctermfg=2 guifg=white
hi MoreMsg ctermfg=40 guifg=green
hi NonText ctermfg=40 guifg=green gui=none
hi Normal ctermbg=0 guibg=gray10 ctermfg=40 guifg=lightgreen
hi Operator ctermfg=40 guifg=green
hi PreProc ctermfg=40 guifg=green
hi Search ctermbg=120 guibg=yellow guifg=black
hi Special ctermfg=40 guifg=green
hi Statement cterm=bold gui=bold ctermfg=40 guifg=lightgreen
hi StatusLineTerm ctermbg=15 guibg=lightgreen
hi StatusLineTerm term=none ctermbg=40 guibg=green ctermfg=0 guifg=gray10
hi StatusLineTermNC ctermbg=15 guibg=lightgreen
hi StatusLineTermNC term=none ctermbg=40 guibg=green ctermfg=0 guifg=darkgreen
hi String ctermfg=40 guifg=green
hi Todo cterm=none ctermfg=40 guifg=green gui=none
hi Type ctermfg=40 guifg=green
hi Visual term=reverse ctermbg=120 guibg=darkgreen ctermfg=0 guifg=gray10 gui=bold
hi VertSplit ctermfg=232 guifg=darkgreen cterm=none gui=none
hi Question ctermfg=40 guifg=green
hi StatusLine cterm=none gui=none ctermfg=2 guifg=gray10 ctermbg=232 guibg=green
hi StatusLineNC cterm=none gui=none ctermfg=40 guifg=lightgreen ctermbg=234 guibg=darkgreen
hi Pmenu ctermbg=232 guibg=darkgreen ctermfg=40 guifg=green
hi PmenuSel ctermbg=40 guibg=lightgreen ctermfg=232 guifg=black
hi MatchParen ctermbg=232 guibg=darkred ctermfg=2 guifg=yellow
hi diffAdded ctermfg=2 guifg=white cterm=none gui=none
hi diffRemoved ctermfg=1 guifg=gray20
