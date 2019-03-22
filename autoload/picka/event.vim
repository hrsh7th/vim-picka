function! picka#event#get()
  return s:Event
endfunction

let s:Event = {
      \   '_events': {}
      \ }

function! s:Event.subscribe(name, fn)
  let self._events[a:name] = get(self._events, a:name, [])
  call add(self._events[a:name], a:fn)
endfunction

function! s:Event.unsubscribe(name, fn)
  let self._events[a:name] = get(self._events, a:name, [])
  let idx = index(self._events[a:name], a:fn)
  if idx >= 0
    call remove(self._events[a:name], idx)
  endif
endfunction

function! s:Event.emit(name, ...)
  for Fn in get(self._events, a:name, [])
    call call(Fn, a:000)
  endfor
endfunction
