" vim-you-autocorrect.vim - Vim You, autocorrect!
" Author: Rich Cheng <http://whileyouweregone.co.uk>
" Homepage: http://github.com/sedm0784/vim-you-autocorrect
" Copyright: © 2018 Rich Cheng
" Licence: Vim You, Autocorrect! uses the Vim licence.
" Version: 0.1.0

if exists('g:loaded_vim_you_autocorrect') || &compatible
  finish
endif

let g:loaded_vim_you_autocorrect = 1

command EnableAutocorrect call vim_you_autocorrect#enable_autocorrect()
command DisableAutocorrect call vim_you_autocorrect#disable_autocorrect()
