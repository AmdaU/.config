" general parmeters ----------------------------------------------------------
setlocal nu rnu
let g:python3_host_prog = "/home/amda/.pyenv/versions/3.10.4/envs/nvim/bin/python3"
set textwidth=0
set colorcolumn=79

source ~/.config/nvim/extra_funcs/warp.vim
" Controls --------------------------------------------
let mapleader = ";"
inoremap <C-s> <Esc>:w <CR>
nnoremap <C-s> <Esc>:w <CR>
inoremap <C-z> <Esc>ua
inoremap <C-b> <Esc>:NERDTreeToggle<CR>
nnoremap <C-b> :NERDTreeToggle<CR>
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <leader>p :lua require("nabla").popup()<CR>
nnoremap <C-j> <C-w>s<C-w>j:term<CR>:setlocal nonu<CR>i
inoremap <C-j> <Esc><C-w>s<C-w>j:term<CR>i
nnoremap <C-t> :tabnew<CR>
inoremap <C-t> <Esc>:tabnew<CR>
nnoremap <C-w> :tabclose<CR>
inoremap <C-w> <Esc>:tabclose<CR>
nnoremap <C-q> :q<CR>
inoremap <C-q> <Esc>:q<CR>
noremap <silent> <Leader>w :call ToggleWrap()<CR>


" inkscape -------------------------------------------------------------------
inoremap <C-f> <Esc>: silent exec '.!inkscape-figures create "'.getline('.').'" "'.b:vimtex.root.'/figures/"'<CR><CR>:w<CR>
nnoremap <C-f> : silent exec '!inkscape-figures edit "'.b:vimtex.root.'/figures/" > /dev/null 2>&1 &'<CR><CR>:redraw!<CR>


" Spelling check -------------------------------------------------------------
setlocal spell
set spelllang=nl,fr,en_ca
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u


" Plugins!
" ############################################################################
call plug#begin()

" Latex Stuff! ---------------------------------------------------------------
Plug 'lervag/vimtex'
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0
set conceallevel=2
let g:tex_conceal='abdmg'
let g:tex_flavor='latex'
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
au BufEnter *.tex :VimtexCompile

"snippets + autocomplete -----------------------------------------------------

"Plug 'SirVer/ultisnips'
"let g:UltiSnipsExpandTrigger="<tab>"
"let g:UltiSnipsJumpForwardTrigger="<M-l>"
"let g:UltiSnipsJumpBackwardTrigger="<M-h>"
""let g:UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit='snips'
"let g:UltiSnipsSnippetDirectories = ['UltiSnips', "bundle/vim-snippets/UltiSnips"]
Plug 'honza/vim-snippets'

Plug 'neoclide/coc.nvim', {'branch': 'release'}
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
let g:coc_snippet_next = '<M-l>'
let g:coc_snippet_prev = '<M-h>'


" Markdown -------------------------------------------------------------------
Plug 'plasticboy/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }
let g:mkdp_browser = 'surf'
Plug 'jbyuki/nabla.nvim'

" Theme stuff ----------------------------------------------------------------
"Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
"Plug 'dylanaraps/wal.vim'
Plug 'catppuccin/nvim', {' as ': 'catppuccin'}


" git stuff ------------------------------------------------------------------
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/gv.vim'
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog' "Mieux/ differrent de gv?
Plug 'xuyuanp/nerdtree-git-plugin'
let g:NERDTreeGitStatusConcealBrackets = 1


" syntax stuff ---------------------------------------------------------------
Plug 'sheerun/vim-polyglot'
Plug 'vim-syntastic/syntastic'
Plug 'jiangmiao/auto-pairs'
Plug 'sbdchd/neoformat'
autocmd BufWritePost * Neoformat
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}


" nerd stuff ----------------------------------------------------------------- 
Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-surround'
Plug 'preservim/nerdtree'


" status line ----------------------------------------------------------------
Plug 'vim-airline/vim-airline'
"let g:airline#extensions#tabline#enabled = 1
let g:airline_left_sep=''
let g:airline_right_sep=''
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme='deus'


" movement -------------------------------------------------------------------
Plug 'easymotion/vim-easymotion'
Plug 'svermeulen/vim-cutlass'
nnoremap x d
xnoremap x d
nnoremap xx dd
nnoremap X D


" language specific stuff ----------------------------------------------------
Plug 'python-mode/python-mode', { 'for': 'python', 'branch': 'develop' }
Plug 'nvie/vim-flake8'
Plug 'rust-lang/rust.vim'
Plug 'elkowar/yuck.vim'


" random stuff ---------------------------------------------------------------
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

Plug 'brauner/vimtux'
Plug 'folke/which-key.nvim'
set timeoutlen=500

Plug 'lilydjwg/colorizer'
Plug 'jacquesg/p5-Neovim-Ext'
Plug 'wincent/terminus'
Plug 'sjl/gundo.vim'
let g:gundo_prefer_python3 = 1

call plug#end()

" Theme and look -------------------------------------------------------------

colorscheme catppuccin
hi Normal guibg=NONE ctermbg=NONE
hi clear SignColumn
hi LineNr guifg=#626880
hi clear Conceal
"colorscheme wal
"colorscheme tokyonight


" Autosave -------------------------------------------------------------------
let g:autosave_time = 600 
let g:save_time = localtime()
au BufRead,BufNewFile * let g:save_time = localtime()
au CursorHold,CursorHoldI * call UpdateFile()
au CursorMoved,CursorMovedI * call UpdateFile()

function! UpdateFile()
    if &filetype ==# 'tex'
       let g:autosave_time = 5
    endif
    if((localtime() - g:save_time) >= g:autosave_time)
       update
       let b:save_time = localtime()
   endif
endfunction

:set clipboard=unnamedplus

call ToggleWrap()
call ToggleWrap()

lua << EOF
  require("which-key").setup {
  }
EOF
au BufEnter *.md :MarkdownPreview
au BufEnter *.md :set nonu
