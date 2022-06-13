set nu
autocmd TermOpen * setlocal nonu

" inkscape --------------------------------------------
inoremap <C-f> <Esc>: silent exec '.!inkscape-figures create "'.getline('.').'" "'.b:vimtex.root.'/figures/"'<CR><CR>:w<CR>
nnoremap <C-f> : silent exec '!inkscape-figures edit "'.b:vimtex.root.'/figures/" > /dev/null 2>&1 &'<CR><CR>:redraw!<CR>

" Controls --------------------------------------------
inoremap <C-s> <Esc>:w <CR>
noremap <C-s> <Esc>:w <CR>
inoremap <C-z> <Esc>ua
inoremap <C-b> <Esc>:NERDTreeToggle<CR>
nnoremap <C-b> :NERDTreeToggle<CR>
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <leader>p :lua require("nabla").popup()<CR>
let mapleader = ";"
nnoremap <C-j> <C-w>s<C-w>j:term<CR>i
inoremap <C-j> <Esc><C-w>s<C-w>j:term<CR>i

" Spelling check --------------------------------------
setlocal spell
set spelllang=nl,fr,en_ca
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u

inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u

" Autosave --------------------------------------------
let g:save_time = localtime()
au BufRead,BufNewFile * let g:save_time = localtime()
au CursorHold,CursorHoldI * call UpdateFile()
au CursorMoved,CursorMovedI * call UpdateFile()
let g:autosave_time = 600 

function! UpdateFile()
    if &filetype ==# 'tex'
       let g:autosave_time = 5
    endif
    if((localtime() - g:save_time) >= g:autosave_time)
       update
       let b:save_time = localtime()
   endif
endfunction

call plug#begin()

Plug 'lervag/vimtex'
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0
set conceallevel=2
let g:tex_conceal='abdmg'
let g:tex_flavor='latex'

"Plug 'SirVer/ultisnips'
"let g:UltiSnipsExpandTrigger="<tab>"
"let g:UltiSnipsJumpForwardTrigger="<M-l>"
"let g:UltiSnipsJumpBackwardTrigger="<M-h>"
""let g:UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit='snips'
"let g:UltiSnipsSnippetDirectories = ['UltiSnips', "bundle/vim-snippets/UltiSnips"]
Plug 'honza/vim-snippets'

Plug 'plasticboy/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }
let g:mkdp_browser = 'surf'

"Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
"Plug 'dylanaraps/wal.vim'
Plug 'catppuccin/nvim', {' as ': 'catppuccin'}
Plug 'raghur/vim-ghost'
function! s:SetupGhostBuffer()
    if match(expand("%:a"), '\v/ghost-(overleaf)\.com-')
        set ft=tex
    endif
endfunction
augroup vim-ghost
    au!
    au User vim-ghost#connected call s:SetupGhostBuffer()
augroup END

Plug 'preservim/nerdtree'
Plug 'xuyuanp/nerdtree-git-plugin'
let g:NERDTreeGitStatusConcealBrackets = 1

Plug 'sjl/gundo.vim'
let g:gundo_prefer_python3 = 1
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/gv.vim'
Plug 'sheerun/vim-polyglot'
"Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'jbyuki/nabla.nvim'
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'vim-syntastic/syntastic'
Plug 'vim-airline/vim-airline'
"let g:airline#extensions#tabline#enabled = 1
let g:airline_left_sep=''
let g:airline_right_sep=''
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme='deus'

Plug 'easymotion/vim-easymotion'
Plug 'wincent/terminus'
Plug 'python-mode/python-mode', { 'for': 'python', 'branch': 'develop' }
Plug 'svermeulen/vim-cutlass'
nnoremap x d
xnoremap x d
nnoremap xx dd
nnoremap X D

Plug 'rust-lang/rust.vim'
Plug 'nvie/vim-flake8'
Plug 'jiangmiao/auto-pairs'
Plug 'sbdchd/neoformat'
autocmd BufWritePost * Neoformat

Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

Plug 'brauner/vimtux'
Plug 'folke/which-key.nvim'
set timeoutlen=500

Plug 'neoclide/coc.nvim', {'branch': 'release'}
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<TAB>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<TAB>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

imap <TAB> <Plug>(coc-snippets-expand)
vmap <M-l> <Plug>(coc-snippets-select)
let g:coc_snippet_next = '<M-l>'
let g:coc_snippet_prev = '<M-h>'

Plug 'lilydjwg/colorizer'

call plug#end()

"-------------------------------------------------------------------------------

colorscheme catppuccin

"colorscheme wal
"colorscheme tokyonight

:set clipboard=unnamedplus

hi clear Conceal

noremap <silent> <Leader>w :call ToggleWrap()<CR>
function ToggleWrap()
  if &wrap
    "echo "Wrap OFF"
    setlocal nowrap
    set virtualedit=all
    silent! nunmap <buffer> <Up>
    silent! nunmap <buffer> <Down>
    silent! nunmap <buffer> <Home>
    silent! nunmap <buffer> <End>
    silent! iunmap <buffer> <Up>
    silent! iunmap <buffer> <Down>
    silent! iunmap <buffer> <Home>
    silent! iunmap <buffer> <End>
  else
    "echo "Wrap ON"
    setlocal wrap linebreak nolist
    set virtualedit=
    setlocal display+=lastline
    nnoremap <silent> j gj
    nnoremap <silent> k gk
    noremap  <buffer> <silent> <Up>   gk
    noremap  <buffer> <silent> <Down> gj
    noremap  <buffer> <silent> <Home> g<Home>
    noremap  <buffer> <silent> <End>  g<End>
    inoremap <buffer> <silent> <Up>   <C-o>gk
    inoremap <buffer> <silent> <Down> <C-o>gj
    inoremap <buffer> <silent> <Home> <C-o>g<Home>
    inoremap <buffer> <silent> <End>  <C-o>g<End>
  endif
endfunction

call ToggleWrap()
call ToggleWrap()

au BufEnter *.md :MarkdownPreview

au BufEnter *.tex :VimtexCompile

lua << EOF
  require("which-key").setup {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
EOF
