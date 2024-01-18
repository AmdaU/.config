" general parmeters ----------------------------------------------------------
setlocal nu rnu
let g:python3_host_prog = "/home/amda/.config/nvim/.venv/bin/python3"
set textwidth=0

if &filetype ==# 'jl'
  set colorcolumn=92
else
  set colorcolumn=79
endif

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

noremap <leader>ve :VimtexErrors<CR>
noremap <leader>vc :VimtexCompile<CR>
noremap <leader>vv :VimtexView<CR>

" disabling arrow keys
inoremap <Up> <Nop>
inoremap <Down> <Nop>
noremap <Up> <Nop>
noremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>

function! Append_dash()
  let line = line('.')
  call feedkeys("$bea \<Esc>D")
  let result = substitute(col('.'), '\d\+', '\=' . &colorcolumn . ' - submatch(0) - 2', '')
  call feedkeys(result . "a-\<Esc>")
endfunction

noremap <Leader>d :call Append_dash()<CR>

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
"let g:tex_flavor='latex'
let g:vimtex_compiler_engine = 'latexmk'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=1
set conceallevel=2
let g:tex_conceal='abdmg'
function! s:startlatex()
  :VimtexCompile
  ":VimtexView
endfunction
"let g:vimtex_view_use_temp_files = 0
au BufEnter *.tex call s:startlatex()

"Plug 'raghur/vim-ghost'
"function! s:SetupGhostBuffer()
    "if match(expand("%:a"), '\v/ghost-(overleaf)\.com-')
        "set ft=tex
    "endif
"endfunction
"augroup vim-ghost
    "au!
    "au User vim-ghost#connected call s:SetupGhostBuffer()
"augroup END

"snippets + autocomplete -----------------------------------------------------

Plug 'SirVer/ultisnips'
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<M-l>"
let g:UltiSnipsJumpBackwardTrigger="<M-h>"
"let g:UltiSnipsSnippetDirectories = [expand("$HOME") . "/.config/snips/"]
let g:UltiSnipsSnippetDirectories = ['UltiSnips', "bundle/vim-snippets/UltiSnips",expand("$HOME") . "/.config/snips/"]
Plug 'honza/vim-snippets'


"if &filetype !=# 'tex'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
inoremap <expr> <cr> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"


" Markdown -------------------------------------------------------------------
Plug 'plasticboy/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }
let g:mkdp_browser = 'surf'
Plug 'jbyuki/nabla.nvim'


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
"let g:neoformat_verbose = 1
let g:neoformat_python_autopep8 = {
            \ 'exe': 'autopep8',
            \ 'args': ['--max-line-length 80'],
            \ 'replace': 1, 
            \ 'stdin': 1, 
            \ 'env': ["DEBUG=1"], 
            \ 'valid_exit_codes': [0, 23],
            \ 'no_append': 1,
            \ }
"let g:neoformat_enabled_python = ['black']

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
"Plug 'nvim-telescope/telescope.nvim'
"nnoremap <leader>ff <cmd>Telescope find_files<cr>
"nnoremap <leader>fg <cmd>Telescope live_grep<cr>
"nnoremap <leader>fb <cmd>Telescope buffers<cr>
"nnoremap <leader>fh <cmd>Telescope help_tags<cr>

Plug 'brauner/vimtux'
Plug 'folke/which-key.nvim'
set timeoutlen=500

Plug 'lilydjwg/colorizer'
Plug 'jacquesg/p5-Neovim-Ext'
Plug 'wincent/terminus'
Plug 'sjl/gundo.vim'
let g:gundo_prefer_python3 = 1

Plug 'rbgrouleff/bclose.vim'
Plug 'francoiscabrol/ranger.vim'

Plug 'hura/vim-asymptote'
au BufEnter *.asy inoremap <C-s> <Esc>:w <CR>:!asy %<CR>
au BufEnter *.asy nnoremap <C-s> <Esc>:w <CR>:!asy %<CR>

" Theme stuff ----------------------------------------------------------------
"Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
"Plug 'dylanaraps/wal.vim'
Plug 'catppuccin/nvim', {' as ': 'catppuccin'}

"Plug 'aduros/ai.vim'
Plug 'madox2/vim-ai'
"let $OPENAI_API_KEY=readfile(expand('~/.openai.secrets'))[0]
vnoremap <silent> <leader>g :AI fix grammar and spelling and replace slang and contractions with a formal academic writing style<CR>
let g:vim_ai_chat = {
\  "options": {
\    "model": "gpt-4",
\    "temperature": 0.2,
\  },
\}
"g:ai_completions_model = "gpt-3.5"
let initial_prompt =<< trim END
>>> system

You are going to play a role of a completion engine with following parameters:
Task: Provide compact code/text completion, generation, transformation or explanation
Topic: general programming and text editing
Style: Plain result without any commentary, unless commentary is necessary
Audience: Users of text editor and programmers that need to transform/generate text
END
let chat_engine_config = {
\  "engine": "chat",
\  "options": {
\    "model": "gpt-4",
\    "max_tokens": 1000,
\    "temperature": 0.1,
\    "request_timeout": 20,
\    "selection_boundary": "",
\    "initial_prompt": initial_prompt,
\  },
\}

let g:vim_ai_complete = chat_engine_config
let g:vim_ai_edit = chat_engine_config
Plug 'christoomey/vim-tmux-navigator'

Plug 'JuliaEditorSupport/julia-vim'
"let g:latex_to_unicode_auto = 1

call plug#end()

" Theme and look -------------------------------------------------------------

"colorscheme wal
"colorscheme tokyonight
colorscheme catppuccin
hi Normal guibg=NONE ctermbg=NONE
hi clear SignColumn
hi LineNr guifg=#626880
hi clear Conceal


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

set clipboard+=unnamedplus

call ToggleWrap()
call ToggleWrap()

lua << EOF
  require("which-key").setup {
  }
EOF
au BufEnter *.md :MarkdownPreview
au BufEnter *.md :set nonu
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>
