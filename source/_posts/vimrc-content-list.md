---
title: .vimrc content list
date: 2023-11-08 22:42:05
tags:
---

个人使用的vimrc 的配置内容，仅做备份，其他地方可做共享

```shell

# cat ~/.vimrc
set number
set cursorline
" set cursorcolumn
syntax on

set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
	" use vundle manage the plugin list
	Plugin 'VundleVim/Vundle.vim'

	" custom plugin list
	Plugin 'preservim/nerdtree'
	Plugin 'preservim/nerdcommenter'
	Plugin 'majutsushi/tagbar'
	Plugin 'itchyny/lightline.vim'
	Plugin 'luochen1990/rainbow'
	Plugin 'dyng/ctrlsf.vim'
	Plugin 'rust-lang/rust.vim'
	" custom plugin list end, use :PluginInstall install the plugin
call vundle#end()
filetype plugin indent on



" 打开时开启NERDTree ，并把鼠标放到other window里
autocmd StdinReadPre * let s:std_in = 1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') |
	\ execute 'NERDTree' argv()[0] | wincmd p | enew | execute 'cd '.argv()[0] | endif

" 当只有一个窗口打开时，退出该窗口，则直接关闭NERDTree 窗口
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" 打开目录页
nnoremap <C-t> :NERDTreeMirror<CR>:NERDTreeFocus<CR>
nmap <C-y>	:NERDTreeToggle<CR>

" 新建标签页
nmap <C-n> :tabnew
" 关闭标签页
nmap <C-x> :tabclose<CR>
" 下一个标签页
nmap <C-k> :tabnext<CR>
" 上一个标签页
nmap <C-j> :tabprevious<CR>



"  rainbow plugin init
let g:rainbow_active = 1 "0 if you want to enable it later via :RainbowToggle

" tagbar plugin init, must install ctags by "sudo apt install ctags"
nmap <F8> :TagbarToggle<CR>


let g:ctrlsf_position = 'bottom'
nmap <F3>	:CtrlSF
nnoremap <F4> :CtrlSFToggle<CR>


```
