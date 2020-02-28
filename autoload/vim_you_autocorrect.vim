" Set cpoptions so we can use line continuation
let s:save_cpo = &cpoptions
set cpoptions&vim

" Use old regexp engine. Necessary to avoid error E868 when using all the
" equivalence classes, below.
let s:letter_regexp = '\%#=1['
let s:letter_regexp .= '[=a=][=b=][=c=][=d=][=e=]'
let s:letter_regexp .= '[=f=][=g=][=h=][=i=][=j=]'
let s:letter_regexp .= '[=k=][=l=][=m=][=n=][=o=]'
let s:letter_regexp .= '[=p=][=q=][=r=][=s=][=t=]'
let s:letter_regexp .= '[=u=][=v=][=w=][=x=][=y=]'
let s:letter_regexp .= '[=z=]'
" Greek/Coptic
let s:letter_regexp .= 'Ͱ-Ͽ'
" Cyrillic
let s:letter_regexp .= 'Ѐ-ӿ'
" Apostrophe!
let s:letter_regexp .= "'"
let s:letter_regexp .= ']$'

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

  " N.B. It would probably be better just to check the last 4 bytes, but that
  " would require doing MATHS: I'm guessing this is still pretty quick unless
  " your line is *really* long. (I'm also not sure if that would break if the
  " start of the last 4 bytes comes halfway through a code point.)
  if empty(line)
        \ ||
        \ line[:edit_pos[2] - 2] !~? s:letter_regexp
    " Jump to the error
    silent! keepjumps normal! [s

    let spell_pos = getpos('.')

    try
      " When there is no spelling mistake, although the cursor hasn't moved, the
      " value for `spell_pos` is still one column back from `edit_pos`. I don't
      " really understand why this is.
      let weird_spell_pos = [-1, 0, 0]
      let weird_spell_pos[1] = spell_pos[1]
      let weird_spell_pos[2] = spell_pos[2] + 1

      " Check:
      "
      " a). That a spelling mistake exists (i.e. if the cursor moved),
      " b). That the spelling mistake is behind us (we might have wrapped around
      "     to a mistake later in the buffer),
      " c). That the spelling mistake is within the area covered by the current
      "     insert session. We don't want to leap back to earlier mistakes.
      "
      " I also considered an approach where I checked if jumping back a word
      " took us to same position as `[s`: in this way we'd only check the most
      " recent word we typed. This doesn't work because:
      "
      " a). We can't use `b` because that will break for apostrophes.
      " b). We can't use `B` because that will break for stuff-like-this.
      "
      " I guess I could use a backwards search using the same regular expression
      " to find beginning of the "spell-word". This would fire correctly when we
      " e.g. change only the second half of a word with our insert. If this
      " weren't just a joke plugin, that should probably go on the roadmap or
      " issues list.
      if !s:pos_same(weird_spell_pos, edit_pos)
            \ &&
            \ s:pos_before(spell_pos, edit_pos)
            \ &&
            \ (s:pos_before(s:start_pos, spell_pos) || s:pos_same(s:start_pos, spell_pos))
        let old_length = strlen(getline('.'))

        let w:vim_you_autocorrect_last_pos = spell_pos

        " Save the original spelling of the most recent autocorrection so we
        " can revert it
        if edit_pos[1] == spell_pos[1]
          let w:vim_you_autocorrect_before_correction = getline('.')[spell_pos[2] - 1:edit_pos[2] - 3]
        elseif edit_pos[1] == spell_pos[1] + 1
          " FIXME: Is it possible that the spelling error isn't at the end of
          "        the line? How?
          let w:vim_you_autocorrect_before_correction = getline('.')[spell_pos[2] - 1:]
        else
          " FIXME: The spelling error isn't on this line or at the end of the
          "        previous line. How did this happen?
          unlet w:vim_you_autocorrect_before_correction
          unlet w:vim_you_autocorrect_last_pos
        endif

        " Correct the error.
        keepjumps normal! 1z=

        call s:clear_highlight()

        if edit_pos[1] == spell_pos[1]
          " Adjust cursor position if the replacement is a different length
          " and is on same line as us.
          let edit_pos[2] = edit_pos[2] + strlen(getline('.')) - old_length

          let w:vim_you_autocorrect_after_correction = getline('.')[spell_pos[2] - 1:edit_pos[2] - 3]
        elseif edit_pos[1] == spell_pos[1] + 1
          let w:vim_you_autocorrect_after_correction = getline('.')[spell_pos[2] - 1:]
        else
          " FIXME: How did we get in here?
          unlet w:vim_you_autocorrect_after_correction
          unlet w:vim_you_autocorrect_last_pos
        endif
          call s:highlight_correction(spell_pos)
      endif
    finally
      " Reset the cursor position.
      silent! call setpos('.', edit_pos)
    endtry
  endif
endfunction

function! s:highlight_correction(spell_pos)
  if exists('w:vim_you_autocorrect_after_correction')
    let s:match_id = matchadd('AutocorrectGood', '\v%'
          \ . a:spell_pos[1] . 'l%'
          \ . a:spell_pos[2] . 'c' . repeat('.', len(w:vim_you_autocorrect_after_correction)))
    call timer_start(10000, {timer_id -> s:clear_highlight()})
  endif
endfunction

" Clear the match of the autocorrected word
function! s:clear_highlight()
  if exists('s:match_id')
    call matchdelete(s:match_id)
    unlet s:match_id
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
  if !&spell
    " We'll need to unset spell when we disable the plugin
    let w:vim_you_autocorrect_reset_spell = 1
    setlocal spell
  endif

  silent! call <SID>remove_autocommands()
  augroup vim_you_autocorrect
    autocmd InsertEnter <buffer> call <SID>reset_start_pos()
    autocmd CursorMovedI <buffer> call <SID>autocorrect()
  augroup END

  highlight link AutocorrectGood SpellBad
endfunction

function! vim_you_autocorrect#disable_autocorrect() abort
  " We don't really want to report errors to the user if the attempt to disable
  " when it's already disabled: use `silent!`
  silent! call <SID>remove_autocommands()

  " Unset spell if we set it
  if exists('w:vim_you_autocorrect_reset_spell')
    unlet w:vim_you_autocorrect_reset_spell
    setlocal nospell
  endif
endfunction

" This gets the line, and the start and end positions of the word that was
" substituted in when making the correction.
function! s:get_line_and_positions() abort
  let corrected_line = getline(w:vim_you_autocorrect_last_pos[1])
  let sp = w:vim_you_autocorrect_last_pos[2] - 1
  let ep = sp + strlen(w:vim_you_autocorrect_after_correction)

  return [corrected_line, sp, ep]
endfunction

function! vim_you_autocorrect#undo_last() abort
  if exists('w:vim_you_autocorrect_last_pos')
    let [corrected_line, sp, ep] = s:get_line_and_positions()

    " Only undo if the correction hasn't been changed subsequently
    if corrected_line[sp:ep - 1] ==# w:vim_you_autocorrect_after_correction
      let edit_pos = getpos('.')

      if sp > 0
        let line_before = corrected_line[:sp - 1]
      else
        let line_before = ''
      endif
      let line_after = corrected_line[ep:]

      call setline(w:vim_you_autocorrect_last_pos[1],
            \ line_before .
            \ w:vim_you_autocorrect_before_correction .
            \ line_after)

      if edit_pos[1] == w:vim_you_autocorrect_last_pos[1]
            \ && edit_pos[2] >
            \      w:vim_you_autocorrect_last_pos[2] +
            \      strlen(w:vim_you_autocorrect_before_correction)
        " N.B. Don't really care what happens to cursor if it's between the
        "      end before and the end after the correction. There's no obvious
        "      "right" answer. Therefore arbitrarily selecting the "before"
        "      end. Could also have used the "after" or the max or the min.

        " Adjust the cursor position to account for changes in length.
        "
        " N.B. We're adjusting the position of the cursor correctly here, but
        "      marks on the line won't move. In particular, the `` mark isn't
        "      moved correctly, so you can't jump back to the correct position
        "      in e.g. a mapping.
        let adjustment = strlen(w:vim_you_autocorrect_before_correction) -
              \ strlen(w:vim_you_autocorrect_after_correction)

        let edit_pos[2] += adjustment
        silent! call setpos('.', edit_pos)
        call s:clear_highlight()
      endif
    endif

    unlet w:vim_you_autocorrect_last_pos
  endif
endfunction

function! vim_you_autocorrect#jump_to_last() abort
  if exists('w:vim_you_autocorrect_last_pos')
    let [corrected_line, sp, ep] = s:get_line_and_positions()

    " Only move if the correction hasn't been changed subsequently
    if corrected_line[sp:ep - 1] ==# w:vim_you_autocorrect_after_correction
      " Add current position to the jumplist
      normal! m'

      " And jump
      silent! call setpos('.', w:vim_you_autocorrect_last_pos)
    endif
  endif
endfunction

" Restore user's cpoptions setting
let &cpoptions = s:save_cpo
unlet s:save_cpo
