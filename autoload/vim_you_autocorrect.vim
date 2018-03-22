function! s:autocorrect() abort
  let edit_pos = getpos('.')

  if s:pos_before(edit_pos, s:start_pos)
    " If the user backspaces past the position where they entered insert mode,
    " we still want to correct their mistakes.
    "
    " This might not work well for HERETICS who use the arrow keys in insert
    " mode, but that's really on them.
    let s:start_pos = edit_pos
  endif

  let line = getline('.')

  if strlen(line) == 0
        \ ||
        \ (line[edit_pos[2] - 2] =~ '\W' && line[edit_pos[2] - 2] != "'")
    " Jump to the error
    silent! keepjumps normal! [s

    let spell_pos = getpos('.')

    " When there is no spelling mistake, although the cursor hasn't moved, the
    " value for `spell_pos` is still one column back from `edit_pos`. I don't
    " really understand why this is.
    let weird_spell_pos = [-1, 0, 0]
    let weird_spell_pos[1] = spell_pos[1]
    let weird_spell_pos[2] = spell_pos[2] + 1

    " Check:
    "
    " a). That a spelling mistake exists (i.e. if the cursor moved),
    " a). That the spelling mistake is behind us (we might have wrapped around
    "     to a mistake later in the buffer),
    " b). That the spelling mistake is within the area covered by the current
    "     insert session. We don't want to leap back to earlier mistakes.
    if !s:pos_same(weird_spell_pos, edit_pos)
          \ &&
          \ s:pos_before(spell_pos, edit_pos)
          \ &&
          \ (s:pos_before(s:start_pos, spell_pos) || s:pos_same(s:start_pos, spell_pos))
      let old_length = strlen(getline('.'))

      " Correct the error.
      keepjumps normal! z=1<CR>

      " Adjust cursor position if the replacement is a different length and is
      " on same line as us.
      if edit_pos[1] == spell_pos[1]
        let edit_pos[2] = edit_pos[2] + strlen(getline('.')) - old_length
      endif
    endif

    " Reset the cursor position.
    silent! keepjumps call setpos('.', edit_pos)
  endif
endfunction

function! s:reset_start_pos() abort
  let s:start_pos = getpos('.')
endfunction

" Returns true if pos1 is earlier in the buffer than pos2
function! s:pos_before(pos1, pos2) abort
  return a:pos1[1] < a:pos2[1]
        \ || a:pos1[1] == a:pos2[1] && a:pos1[2] < a:pos2[2]
endfunction

function! s:pos_same(pos1, pos2) abort
  return a:pos1[1] == a:pos2[1] && a:pos1[2] == a:pos2[2]
endfunction

function! s:remove_autocommands() abort
  autocmd! vim_you_autocorrect InsertEnter,CursorMovedI <buffer>
endfunction

function! vim_you_autocorrect#enable_autocorrect() abort
  " Save 'spell'
  " FIXME: 'spell' is window local, but the autocommands are buffer local.
  let w:vim_you_autocorrect_spell = &spell
  setlocal spell

  silent! call <SID>remove_autocommands()
  augroup vim_you_autocorrect
    autocmd InsertEnter <buffer> call <SID>reset_start_pos()
    autocmd CursorMovedI <buffer> call <SID>autocorrect()
  augroup END
endfunction

function! vim_you_autocorrect#disable_autocorrect() abort
  " We don't really want to report errors to the user if the attempt to disable
  " when it's already disabled: use `silent!`
  silent! call <SID>remove_autocommands()

  " Restore 'spell'
  if exists('w:vim_you_autocorrect_spell')
    if !w:vim_you_autocorrect_spell
      setlocal nospell
    endif
  endif
endfunction

