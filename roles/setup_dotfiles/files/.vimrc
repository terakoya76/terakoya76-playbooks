syntax on
set fileformats=unix,dos,mac
set fileencodings=utf-8,sjis
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4
set cursorline
set number
set incsearch
set wildmenu wildmode=list:full

highlight Normal ctermbg=black ctermfg=grey
highlight StatusLine term=none cterm=none ctermfg=black ctermbg=grey
highlight CursorLine term=none cterm=none ctermfg=none ctermbg=darkgray
highlight ExtraWhitespace ctermbg=red guibg=red

"for US keyboard
nnoremap ; :
nnoremap : ;

" enable mouse operation
set mouse=a

" enable yank to clipboard
set clipboard=unnamedplus

"plugins
call plug#begin('~/.vim/plugged')
Plug 'altercation/vim-colors-solarized'
Plug 'bronson/vim-trailing-whitespace'
Plug 'jiangmiao/auto-pairs'
Plug 'itchyny/lightline.vim'

Plug 'Shougo/vimproc.vim'
Plug 'Shougo/denite.nvim'
Plug 'majutsushi/tagbar'
Plug 'tpope/vim-fugitive' " manipulate git from vim
Plug 'terryma/vim-multiple-cursors'
Plug 'scrooloose/nerdtree'
Plug 'junegunn/vim-easy-align'

Plug 'szw/vim-tags'
"Plug 'lighttiger2505/gtags.vim'
"Plug 'jsfaint/gen_tags.vim'

"Plug 'vim-syntastic/syntastic'
Plug 'w0rp/ale'
Plug 'sheerun/vim-polyglot'

Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'fatih/vim-go', {
\ 'for': 'go',
\ 'do': ':GoUpdateBinaries' }
Plug 'eagletmt/ghcmod-vim', { 'for': 'haskell' }
call plug#end()

"solarized personal conf
set background=dark
let g:solarized_termcolors=256
colorscheme solarized

"lightline and ale
let g:lightline = {
\  'active': {
\    'right': [['ale']]},
\  'component_function': {
\    'ale': 'LLAle',
\  },
\}

function! LLAle()
  let l:count = ale#statusline#Count(bufnr(''))
  let l:errors = l:count.error + l:count.style_error
  let l:warnings = l:count.warning + l:count.style_warning
  return l:count.total == 0 ? 'OK' : 'E:' . l:errors . ' W:' . l:warnings
endfunction

"linting w/ ale
"let g:ale_lint_on_enter = 0
let g:ale_linters = {
\  'javascript': ['eslint'],
\  'haskell': ['hlint'],
\}
let g:ale_fixers = {
\  '*': ['remove_trailing_lines', 'trim_whitespace'],
\  'javascript': ['prettier', 'eslint'],
\  'ruby': ['rubocop'],
\  'haskell': ['hlint'],
\}
let g:ale_fix_on_save = 1
let g:ale_completion_enabled = 1
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '--'
let g:ale_javascript_prettier_use_local_config = 1

"denite
nnoremap [denite] <Nop>
nmap <C-c> [denite]

"現在開いているファイルのディレクトリ下のファイル一覧。
nnoremap <silent> [denite]f :<C-u>DeniteBufferDir
      \ -direction=topleft -cursor-wrap=true file file:new<CR>
"バッファ一覧
nnoremap <silent> [denite]b :<C-u>Denite -direction=topleft -cursor-wrap=true buffer<CR>
"レジスタ一覧
nnoremap <silent> [denite]r :<C-u>Denite -direction=topleft -cursor-wrap=true -buffer-name=register register<CR>
"最近使用したファイル一覧
nnoremap <silent> [denite]m :<C-u>Denite -direction=topleft -cursor-wrap=true file_mru<CR>
"ブックマーク一覧
nnoremap <silent> [denite]c :<C-u>Denite -direction=topleft -cursor-wrap=true bookmark<CR>
"ブックマークに追加
nnoremap <silent> [denite]a :<C-u>DeniteBookmarkAdd<CR>
"grep
nnoremap <silent> [denite]l :<C-u>Denite -direction=topleft -cursor-wrap=true grep<CR>

".git以下のディレクトリ検索
nnoremap <silent> [denite]k :<C-u>Denite -direction=topleft -cursor-wrap=true
      \ -path=`substitute(finddir('.git', './;'), '.git', '', 'g')`
      \ file_rec/git<CR>

call denite#custom#source('file'    , 'matchers', ['matcher_cpsm', 'matcher_fuzzy'])

call denite#custom#source('buffer'  , 'matchers', ['matcher_regexp'])
call denite#custom#source('file_mru', 'matchers', ['matcher_regexp'])

call denite#custom#alias('source', 'file_rec/git', 'file_rec')
call denite#custom#var('file_rec/git', 'command',
  \ ['git', 'ls-files', '-co', '--exclude-standard'])

call denite#custom#map('insert', '<C-N>', '<denite:move_to_next_line>', 'noremap')
call denite#custom#map('insert', '<C-P>', '<denite:move_to_previous_line>', 'noremap')
call denite#custom#map('insert', '<C-W>', '<denite:move_up_path>', 'noremap')

"deniteのgrepをripgrepで置換
if executable('rg')
  call denite#custom#var('file_rec', 'command',
        \ ['rg', '--files', '--glob', '!.git'])
  call denite#custom#var('grep', 'command', ['rg'])
endif

"ctag
set tags+=.git/tags
"augroup ctags
"  autocmd!
"  autocmd BufWritePost * silent !ctags -R --exclude=node_modules --exclude=vendor -f .git/tags
"augroup END

let g:vim_tags_project_tags_command = "/usr/local/bin/ctags -R {OPTIONS} {DIRECTORY} 2>/dev/null"
let g:vim_tags_gems_tags_command = "/usr/local/bin/ctags -R {OPTIONS} `bundle show --paths` 2>/dev/null"

" gtags
"let g:Gtags_Auto_Map = 0
"let g:Gtags_OpenQuickfixWindow = 1
"nmap <silent> K :<C-u>exe("Gtags ".expand('<cword>'))<CR>
"nmap <silent> R :<C-u>exe("Gtags -r ".expand('<cword>'))<CR>

"let g:gen_tags#ctags_auto_gen = 1
"let g:gen_tags#gtags_auto_gen = 1
"let g:gen_tags#ctags_use_cache_dir = 0

"tagbar
set statusline=%F%m%r%h%w\%=%{tagbar#currenttag('[%s]','')}\[Pos=%v,%l]\[Len=%L]
let g:tagbar_width = 30
nnoremap <silent> <C-c>t :TagbarToggle<CR>

" NERDTree
autocmd vimenter * NERDTree

" vim-easy-align
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)
