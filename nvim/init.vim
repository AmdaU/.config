set nu

inoremap <C-f> <Esc>: silent exec '.!inkscape-figures create "'.getline('.').'" "'.b:vimtex.root.'/figures/"'<CR><CR>:w<CR>
nnoremap <C-f> : silent exec '!inkscape-figures edit "'.b:vimtex.root.'/figures/" > /dev/null 2>&1 &'<CR><CR>:redraw!<CR>

call plug#begin()

"Plug 'lervag/vimtex'

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

call plug#end()

hi clear Conceal

au BufEnter *.md :MarkdownPreview
