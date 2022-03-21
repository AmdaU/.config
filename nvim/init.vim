set nu

inoremap <C-f> <Esc>: silent exec '.!inkscape-figures create "'.getline('.').'" "'.b:vimtex.root.'/figures/"'<CR><CR>:w<CR>
nnoremap <C-f> : silent exec '!inkscape-figures edit "'.b:vimtex.root.'/figures/" > /dev/null 2>&1 &'<CR><CR>:redraw!<CR>

call plug#begin()

Plug 'lervag/vimtex'

let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0
set conceallevel=2
let g:tex_conceal='abdmg'
let g:tex_flavor='latex'

Plug 'SirVer/ultisnips'

let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<M-l>"
let g:UltiSnipsJumpBackwardTrigger="<M-h>"
"let g:UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit='snips'
let g:UltiSnipsSnippetDirectories = ['UltiSnips', "bundle/vim-snippets/UltiSnips"]

Plug 'honza/vim-snippets'

Plug 'iamcco/markdown-preview.nvim'

let g:mkdp_browser = 'surf'

Plug 'folke/tokyonight.nvim', { 'branch': 'main' }

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
			
call plug#end()

colorscheme tokyonight

let g:clipboard = {  
    \ 'name': 'myClipboard',  
    \ 'copy': {  
    \    '+': 'copyq add -',  
    \    '*': 'copyq add -',  
    \ },
    \ 'paste': {
    \    '+': '+',
    \    '*': '*',
    \ },
    \ 'cache_enabled': 1,
    \ }

hi clear Conceal

noremap <silent> <Leader>w :call ToggleWrap()<CR>
function ToggleWrap()
  if &wrap
    echo "Wrap OFF"
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
    echo "Wrap ON"
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

au BufEnter *.md :MarkdownPreview
