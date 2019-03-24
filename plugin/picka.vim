if exists('g:loaded_picka')
  finish
endif

let g:loaded_picka = 1

let s:try_wininfo = get(getwininfo(), 0, {})
if !has_key(s:try_wininfo, 'topline')
  echomsg 'getwininfo() was not provied `topline` property.'
endif


