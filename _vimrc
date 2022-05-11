set noundofile
set backupdir=>$TEMP,C:/tmp,c:\temp,. " backup directory
set directory=>$TEMP,C:/tmp,c:\temp,. " swap directory
set vb t_vb=          " visual bell disabled
set shortmess=I
set nobackup
set ts=2
set sw=2
set number
set expandtab
set ambiwidth=double

map <F5> a<C-R>=strftime("%Y-%m-%d")<CR><Esc>
imap <F5> <C-R>=strftime("%Y-%m-%d")<CR>
map <F2> :bp<CR>
map <F3> :bn<CR>
map <F4> :bd<CR>
map <F8> :cp<CR>
map <F9> :cn<CR>
map <C-F8> :tp<CR>
map <C-F9> :tn<CR>
nnoremap <F11> :tabprevious<CR>
nnoremap <F12> :tabNext<CR>
map <C-K> :cp<CR>
map <C-J> :cn<CR>
map <C-H> :cc<CR>
nnoremap <Leader>^ :cf &errorfile
cnoremap bro bro filter  ol<Left><Left><Left>
set tags=tags;,ctags,$temp/mono.doubt
set shell=C:\Program\ Files\WindowsApps\Microsoft.PowerShell_7.2.1.0_x64__8wekyb3d8bbwe\pwsh.exe
