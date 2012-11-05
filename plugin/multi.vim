let s:marks = []
function! s:multi_on(bang, arg)
  let arg = a:arg
  let s:marks = []
  match NONE
  let pos = searchpos(arg, 'c')
  if pos == [0,0]
    echohl WarningMsg | echo "No matches" | echohl None
    return
  endif
  while 1
    let found = searchpos(arg, 'w')
    if found == [0,0] || found == pos
      break
    else
      let s:marks += [found]
    endif
  endwhile
  silent! exe "match" "Search" "/".arg."/"
  call setpos('.', pos)
  augroup MultiGroup
    au!
    au InsertCharPre <buffer> call s:multi_push()
    au InsertLeave <buffer> call s:multi_off()
    silent! inoremap <buffer> <cr> <nop>
    silent! inoremap <buffer> <silent> <bs> <c-r>=<sid>multi_bs()<cr>
    silent! inoremap <buffer> <silent> <del> <c-r>=<sid>multi_del()<cr>
  augroup END
  startinsert
  if a:bang == '!' || arg == '$'
    call feedkeys("\<right>", 'n')
  endif
endfunction

function! s:multi_off()
  au! InsertCharPre <buffer>
  au! InsertLeave <buffer>
  imapclear <buffer>
  match NONE
  return ''
endfunction

let s:char = ''

function! s:multi_push()
  let s:char .= v:char
  call feedkeys("\<plug>(multi-update)", 'm')
endfunction

function! s:multi_bs()
  let pos = getpos('.')
  for m in s:marks
    let line = getline(m[0])
    if m[1] > 1
      let line = matchstr(line[:m[1]-2], '^\zs.*\ze.').line[m[1]-1:]
      call setline(m[0], line)
      let m[1] -= 1
    endif
  endfor
  let s:char = ''
  return pos[2] == 1 ? '' : "\<bs>"
endfunction

function! s:multi_del()
  let pos = getpos('.')
  for m in s:marks+[pos[1:2]]
    let line = getline(m[0])
    if m[1] < len(line)
      if m[1] > 1 
        let line = line[:m[1]-2].matchstr(line[m[1]-1:], '.\zs.*')
      else
        let line = matchstr(line[m[1]-1:], '.\zs.*')
      endif
      call setline(m[0], line)
    endif
  endfor
  let s:char = ''
  return ''
endfunction

function! s:multi_update()
  let pos = getpos('.')
  for m in s:marks
    let line = getline(m[0])
    let line = m[1] > 1 ? (line[:m[1]-2].s:char.line[m[1]-1:]) : (s:char.line[m[1]-1:])
    call setline(m[0], line)
    for r in s:marks
      if r[0] == m[0] && r[1] > m[1]
        let r[1] += len(s:char)
      endif
    endfor
    let m[1] += len(s:char)
  endfor
  call setpos('.', pos)
  let s:char = ''
  return ''
endfunction

command! -nargs=1 -bang Multi call s:multi_on('<bang>', <q-args>)
inoremap <silent> <plug>(multi-update) <c-r>=<sid>multi_update()<cr>
