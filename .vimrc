set nobackup
set backupdir=>/tmp,. " backup directory
set directory=>/tmp,. " swap directory
set vb t_vb=          " visual bell disabled

syntax on
set hlsearch
colorscheme desert

set ignorecase
set smartcase

set tabstop=2
set shiftwidth=2
set expandtab
set errorfile=.eee0

map <F1> :files<CR>
map <F2> :bprev<CR>
map <F3> :bnext<CR>
map <F4> :bdel<CR>
map <F5> a<C-R>=strftime("%Y-%m-%d")<CR><Esc>
imap <F5> <C-R>=strftime("%Y-%m-%d")<CR>
map <F8> :cp<CR>
map <F9> :cn<CR>

map gC	"+y
map gX	"+x
map gV	"+gP
imap gV	sw=2

set lcs=tab:>.,eol:$,trail:_,extends:\

" tag duplicatin behavior = list choice
nnoremap <C-]> g<C-]>

" C-P completion range
set complete=.,w,b,u,t

" word range
"set iskeyword=@,48-57,_,192-255,# " .vimrc
"set iskeyword=@,48-57,_,192-255   " txt
"set iskeyword=@,48-57,_,192-255,: " perl

set tags=./tags;,tags,ptags
cmap dvd vert diffsplit 
