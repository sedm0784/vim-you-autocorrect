" vim-you-autocorrect.vim - Vim You, autocorrect!
" Author: Rich Cheng <http://whileyouweregone.co.uk>
" Homepage: http://github.com/sedm0784/vim-you-autocorrect
" Copyright: © 2018–2021 Rich Cheng
" Licence: Vim You, Autocorrect! uses the Vim licence.
" Version: 1.1.5

" Set coptions so we can use line continuation
let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('g:loaded_vim_you_autocorrect')
      \ || &compatible
      \ || v:version < 700
      \ || !has('syntax')
      \ || !exists('&spell')

  " Restore user's cpoptions setting
  let &cpoptions = s:save_cpo
  unlet s:save_cpo
  finish
endif

let g:loaded_vim_you_autocorrect = 1

command EnableAutocorrect call vim_you_autocorrect#enable_autocorrect()
command DisableAutocorrect call vim_you_autocorrect#disable_autocorrect()

nnoremap <silent> <Plug>VimyouautocorrectUndo :call vim_you_autocorrect#undo_last()<CR>
nnoremap <silent> <Plug>VimyouautocorrectJump :call vim_you_autocorrect#jump_to_last()<CR>
nnoremap <silent> <Plug>VimyouautocorrectNext :call vim_you_autocorrect#next()<CR>
nnoremap <silent> <Plug>VimyouautocorrectPrevious :call vim_you_autocorrect#previous()<CR>

" Restore user's cpoptions setting
let &cpoptions = s:save_cpo
unlet s:save_cpo
