filetype off
filetype plugin indent on

set nobackup
set backupdir=>/tmp,. " backup directory
set directory=>/tmp,. " swap directory
set vb t_vb=          " visual bell disabled

set enc=utf-8

syntax on
set hlsearch
colorscheme desert
set modeline

set ignorecase
set smartcase

set ambiwidth=double

set tabstop=2
set shiftwidth=2
set expandtab

set ruler " show line-number,column-number
set laststatus=2 " always show file name
set statusline=%F%m%h%w%r\ %<%=[%l,%02v,%%%B]
set errorfile=/tmp/.eee0
set keywordprg=fj\ -A

nmap <F1> :files<CR>
cmap <F1> files<CR>
map <F2> :bprev<CR>
map <F3> :bnext<CR>
map <F4> :bdel<CR>
map <F5> a<C-R>=strftime("%Y-%m-%d")<CR><ESC>
imap <F5> <C-R>=strftime("%Y-%m-%d")<CR>
nnoremap <F8> :cp<CR>
nnoremap <F9> :cn<CR>
nnoremap <C-F8> :tp<CR>
nnoremap <C-F9> :tn<CR>
nnoremap <F11> :tabprevious<CR>
nnoremap <F12> :tabNext<CR>
nnoremap <S-F12> :tabprevious<CR>
map <Leader>^ :cf /tmp/.eee0<CR>
map <Leader>0 :cf /tmp/.eee0<CR>
map <Leader>1 :cf /tmp/.eee1<CR>
map <Leader>2 :cf /tmp/.eee2<CR>
nnoremap <Leader>h :e ~/.fjhist<Bar>$<CR>
noremap <C-K> :cp<CR>
noremap <C-J> :cn<CR>
noremap <C-H> :cc<CR>
nnoremap !fj :!fj 
noremap <expr> <Leader>k ':!fj -A ' . expand("<cword>") . ' '
noremap <expr> <Leader>l ':!fj -L ' . expand("<cword>") . ' '
autocmd BufEnter *.fjhist setlocal autoread

cnoremap bro bro filter  ol<Left><Left><Left>

map gC	"+y
map gX	"+x
map gV	"+gP
imap gV	<ESC>"+gPa

set lcs=tab:>.,eol:$,trail:_,extends:\

" tag duplication behavior = list choice
nnoremap <C-]> g<C-]>

" C-P completion range
set complete=.,w,b,u,t

" word range
"set iskeyword=@,48-57,_,192-255,# " .vimrc
"set iskeyword=@,48-57,_,192-255   " txt
"set iskeyword=@,48-57,_,192-255,: " perl

set tags=./tags;,tags,ptags
cmap dvd vert diffsplit 
cmap bfo bro filter  ol<Left><Left><Left>
set nu
set errorformat=%f:%l:%m
set redrawtime=5000

function! s:delete_hide_buffer()
	let list = filter(range(1, bufnr("$")), "buflisted(v:val)")
  let winlist = range(1, winnr("$"))
  for num in list
    let is_visible = 0
    for w in winlist
      if winbufnr(w) == num
        let is_visible = 1
        break
      endif
    endfor
    if is_visible == 0
      execute "bdel ".num
    endif
  endfor
endfunction

command! Hdelall :call s:delete_hide_buffer()

function! s:fj_L_for_keyword()
  exec '!fj -i -L ' . expand("<cword>")
  if filereadable(&errorfile)
    cf
  endif
endfunction
command! Fjl4kw :call s:fj_L_for_keyword()
"nnoremap <C-@> :Fjl4kw<CR>

function! s:fj_A_for_keyword_angular()
  exec '!fj -i ' . expand("<cword>") . ' .html .css .ts'
  if filereadable(&errorfile)
    cf
  endif
endfunction
command! Fja4kwAngular :call s:fj_A_for_keyword_angular()
nnoremap <C-@> :Fja4kwAngular<CR>

" \x exec current line string as external command
function! s:exec_current_command_line()
  let s:cl = substitute(getline("."), '^\s*\$\s*', '', "")
  let s:cl = substitute(s:cl, '^\s*#\+\s*', '', "")
  if s:cl == ""
    return
  endif
  exec '!echo ' . s:cl . ';' . s:cl
endfunction
command! ExecCurrentCommandLine :call s:exec_current_command_line()
noremap <Leader>x :ExecCurrentCommandLine<CR>

" \b run 'git blame' around current line
function! s:exec_git_blame()
  let s:clnum = line(".")
  let s:slnum1 = s:clnum - 16
  let s:elnum1 = s:clnum - 0
  let s:slnum2 = s:clnum + 1
  let s:elnum2 = s:clnum + 16
  let s:maxlnum = line("$")
  if s:slnum1 < 1
    let s:slnum1 = 1
  endif
  if s:elnum1 < 1
    let s:elnum1 = 1
  endif
  if s:slnum2 > s:maxlnum
    let s:slnum2 = s:maxlnum
  endif
  if s:elnum2 > s:maxlnum
    let s:elnum2 = s:maxlnum
  endif
  exec '!git blame -L ' . s:slnum1 . ',' . s:elnum1 . ' ' . expand("%") . ' && echo "^^^^^^^^" && git blame -L ' . s:slnum2 . ',' . s:elnum2 . ' ' . expand('%')
endfunction
command! ExecGitBlame :call s:exec_git_blame()
noremap <Leader>b :ExecGitBlame<CR>

inoremap LLL log_message('debug',__FILE__.':'.__LINE__.': '.__CLASS__.'->'.__METHOD__.'():'<CR>.preg_replace('/\r?\n/', '', var_export(<CR>$foo<CR>,true)));<ESC>

augroup MyGroup
    autocmd!
    autocmd BufRead,BufNewFile *.js setlocal expandtab tabstop=4 softtabstop=4 shiftwidth=4
    autocmd BufRead,BufNewFile *.php setlocal expandtab tabstop=4 softtabstop=4 shiftwidth=4
    autocmd BufRead,BufNewFile *.html setlocal expandtab tabstop=4 softtabstop=4 shiftwidth=4 foldmethod=indent
    autocmd BufRead,BufNewFile *.sql setlocal expandtab tabstop=4 softtabstop=4 shiftwidth=4 foldmethod=indent
augroup END

vnoremap <Leader>r :s/\<\(and\\|or\\|from\\|inner\\|outer\\|left\\|right\\|on\\|where\\|order\\|grroup\)\>\\|,/\r&/g<CR>

filetype plugin indent on
