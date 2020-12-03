""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader=","

set colorcolumn=80

" tab and intend related ----------

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" Linebreak on 500 characters
set lbr
set tw=500

" took from r/vim/wiki not sure why is better like this
set autoindent
filetype plugin indent on

set wrap
set rnu " set relative numbered lines
set number " show current line number
set nowrap
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set cursorline
set encoding=utf-8
set modifiable
set clipboard+=unnamedplus
set showmatch "show matching bracket when text indicator is over them

" set autoread when file is changed from outside
set autoread 
au FocusGained,BufEnter * checktime

" Better search options
set ignorecase " ignore case when searching  
set smartcase " when searching trying to be smart about cases
"set hlsearch " highlight search result
set incsearch " makes search act like modern browser

"no anoying sound on errors
set noerrorbells " no sound on error
set novisualbell 

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Turn persistent undo on 
"    means that you can undo even when you close a buffer/VIM
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
try
    set undodir=~/.vim_runtime/temp_dirs/undodir
    set undofile
catch
endtry

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors and fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

syntax enable " enable syntax highlighting 
" make code look pretty for python
let python_highlight_all=1

highlight ColorColumn ctermbg=0 guibg=lightgrey

" Flagging unncessary white spaces
" au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.vim/plugged')
Plug 'morhetz/gruvbox'
Plug 'Chiel92/vim-autoformat'
Plug 'ycm-core/Youcompleteme'
Plug 'vim-scripts/indentpython.vim'
Plug 'vim-syntastic/syntastic'
Plug 'nvie/vim-flake8' " for pip8 checking (python)
Plug 'https://github.com/ctrlpvim/ctrlp.vim' " fuzzy file finder
Plug 'preservim/nerdtree'
Plug 'sonph/onehalf', { 'rtp': 'vim' }
Plug 'https://github.com/cocopon/iceberg.vim'
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax' 
call plug#end()


" setting colorscheme
colorscheme gruvbox
set background=dark

" => Ctrlp config--------------------
"
" Quickly find and open a file in the current working directory
let g:ctrlp_map = '<C-f>'
map <leader>j :CtrlP<cr>

" Quickly find and open a buffer
map <leader>b :CtrlPBuffer<cr>

" Quickly find and open a recently opened file
map <leader>f :CtrlPMRU<CR>

let g:ctrlp_max_height = 20
let g:ctrlp_custom_ignore = 'node_modules\|^\.DS_Store\|^\.git\|^\.coffee'

" => NerdTree config------------------
"
let g:NERDTreeWinPos = "left"
let NERDTreeShowHidden=0
let NERDTmeeIgnore = ['\.pyc$', '__pycache__']
let g:NERDTreeWinSize=35
map <leader>nn :NERDTreeToggle<cr>
"map <leader>nb :NERDTreeFromBookmark<Space>
map <leader>nf :NERDTreeFind<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remaps
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" remapping split switching with more intuitive key bindings
nnoremap <C-h> <C-W>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
noremap <C-l> <C-W>l

" enabling normal mode in terminal split windows
tnoremap <Esc> <C-\><C-n>
