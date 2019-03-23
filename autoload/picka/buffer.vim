let s:Event = picka#event#get()

let s:buffer_id = 0

function! picka#buffer#new()
  let instance = extend(deepcopy(s:Buffer), s:Event)
  call instance.constructor()
  return instance
endfunction

let s:Buffer = {}

" create buffer instance
function! s:Buffer.constructor()
  call self.reset()
endfunction

function! s:Buffer.reset()
  call self.unsubscribe_all()

  if has_key(self, 'bufnr')
    execute printf('%sbwipeout', self.bufnr)
  endif

  let s:buffer_id = s:buffer_id + 1
  let self.buffer_id = s:buffer_id

  execute printf('badd picka_buffer_%s', self.buffer_id)
  let self.bufname = printf('picka_buffer_%s', self.buffer_id)
  let self.bufnr = bufnr(self.bufname)
  let self.scope = [1, 2]
  let self.keymap = {}
  call setbufvar(self.bufnr, '&buftype', 'nofile')
  call setbufvar(self.bufnr, '&buflisted', 0)
  call setbufvar(self.bufnr, '&bufhidden', 'hidden')
  call setbufvar(self.bufnr, '&scrolloff', 0)
  call setbufvar(self.bufnr, '&modifiable', 0)

  " init events.
  augroup printf('picka_buffer_%s', self.bufnr)
    autocmd!
    call self.bind('BufWinEnter', function(self.on_buf_win_enter))
    call self.bind('BufWinLeave', function(self.on_buf_win_leave))
    call self.bind('BufWipeout', function(self.on_buf_wipeout))
    call self.bind('CursorMoved', function(self.on_cursor_moved))
  augroup END

  if self.is_visible()
    call self.on_buf_win_enter()
  endif
endfunction

function! s:Buffer.is_visible()
  return bufwinnr(self.bufnr) != -1
endfunction

function! s:Buffer.clear()
  let bufnr = bufnr('%')
  try
    call self.modifiable(v:true)
    execute printf('%sbufdo! 0 delete _', self.bufnr)
    call self.modifiable(v:false)
  finally
    execute printf('%sbuffer', bufnr)
  endtry
endfunction

function! s:Buffer.set(lnum, text)
  if a:lnum == 0
    return
  endif
  call nvim_buf_set_lines(self.bufnr, a:lnum - 1, a:lnum, v:false, [a:text])
endfunction

function! s:Buffer.modifiable(v)
  call setbufvar(self.bufnr, '&modifiable', a:v ? 1 : 0)
endfunction

function! s:Buffer.length()
  return len(getbufline(self.bufnr, 1, '$'))
endfunction

function! s:Buffer.get_scope()
  for wininfo in getwininfo()
    if wininfo.winnr == bufwinnr(self.bufnr)
      return [max([wininfo.topline, 1]), max([wininfo.botline, winheight(bufwinnr(self.bufnr))])]
    endif
  endfor
  return [1, 2]
endfunction

function! s:Buffer.check_state()
  let scope = self.get_scope()
  if scope[0] != self.scope[0] || scope[1] != self.scope[1]
    let self.scope = scope
    call self.emit('change_scope')
  endif
endfunction

function! s:Buffer.bind(event, fn)
  call setbufvar(self.bufnr, printf('picka_buffer_bind_%s', a:event), a:fn)
  execute printf('autocmd! %s <buffer=%s> call getbufvar(%s, "picka_buffer_bind_%s")()',
        \ a:event,
        \ self.bufnr,
        \ self.bufnr,
        \ a:event)
endfunction

function! s:Buffer.mapping(mode, key, fn)
  let self.keymap[a:mode] = get(self.keymap, a:mode, [])
  call add(self.keymap[a:mode], a:key)
  call setbufvar(self.bufnr, printf('picka_buffer_keymap_%s_%s', a:mode, a:key), a:fn)
  call self.apply_mapping()
endfunction

function! s:Buffer.apply_mapping()
  if !self.is_visible()
    return
  endif

  for [mode, maps] in items(self.keymap)
    let self.keymap[mode] = get(self.keymap, mode, [])
    for key in self.keymap[mode]
      execute printf('silent! %s <silent><buffer>%s', { 'inoremap': 'iunmap', 'nnoremap': 'nunmap' }[mode], key)
      execute printf('%s <silent><buffer>%s :<C-u>call getbufvar(%s, "picka_buffer_keymap_%s_%s")()<CR>',
            \ mode,
            \ key,
            \ self.bufnr,
            \ mode,
            \ key)
    endfor
  endfor
endfunction

function! s:Buffer.on_buf_win_enter()
  echomsg 'on_buf_win_enter: ' . self.bufnr
  setlocal listchars=trail:\ 
  setlocal cursorline
  let self.timer_id = timer_start(200, function(self.on_tick), { 'repeat': -1 })
  call self.apply_mapping()
endfunction

function! s:Buffer.on_buf_win_leave()
  echomsg 'on_buf_win_leave: ' . self.bufnr
  call timer_stop(get(self, 'timer_id', -1))
endfunction

function! s:Buffer.on_buf_wipeout()
  echomsg 'on_buf_wipeout: ' . self.bufnr
  call timer_stop(get(self, 'timer_id', -1))
  augroup printf('picka_buffer_%s', self.bufnr)
    autocmd!
  augroup END
endfunction

function! s:Buffer.on_cursor_moved()
  call self.check_state()
endfunction

function! s:Buffer.on_tick(timer_id)
  call self.check_state()
endfunction

