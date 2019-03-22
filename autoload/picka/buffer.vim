let s:Event = picka#event#get()

function! picka#buffer#new()
  let instance = extend(deepcopy(s:Buffer), s:Event)
  call instance.constructor()
  return instance
endfunction

let s:Buffer = {}

" create buffer instance
function! s:Buffer.constructor()
  " create new buffer
  execute printf('badd picka_buffer_%s', bufnr('$') + 1)
  let self.bufname = bufname(bufnr('$'))
  let self.bufnr = bufnr('$')
  let self.scope = [1, 2]
  let self.keymap = {}
  let self.is_visible = v:false
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
endfunction

" --- Methods

" reset
function! s:Buffer.reset()
  let bufnr = bufnr('%')
  try
    call self.modifiable(v:true)
    execute printf('%sbufdo 0,$delete', self.bufnr)
    call self.modifiable(v:false)
  finally
    execute printf('%sbuffer', bufnr)
  endtry
endfunction

" set text for specific lnum
function! s:Buffer.set(lnum, text)
  call nvim_buf_set_lines(self.bufnr, a:lnum - 1, a:lnum, v:false, [a:text])
endfunction

function! s:Buffer.modifiable(v)
  call setbufvar(self.bufnr, '&modifiable', a:v ? 1 : 0)
endfunction

" get scope
function! s:Buffer.get_scope()
  for wininfo in getwininfo()
    if wininfo.winnr == bufwinnr(self.bufnr)
      return [max([wininfo.topline, 1]), max([wininfo.botline, winheight(bufwinnr(self.bufnr))])]
    endif
  endfor
  return [1, 2]
endfunction

" check buffer state
function! s:Buffer.check_state()
  let scope = self.get_scope()
  if scope[0] != self.scope[0] || scope[1] != self.scope[1]
    let self.scope = scope
    call self.emit('change_scope')
  endif
endfunction

" bind events
function! s:Buffer.bind(event, fn)
  call setbufvar(self.bufnr, printf('picka_buffer_bind_%s', a:event), a:fn)
  execute printf('autocmd! %s <buffer=%s> call getbufvar(%s, "picka_buffer_bind_%s")()',
        \ a:event,
        \ self.bufnr,
        \ self.bufnr,
        \ a:event)
endfunction

" keymap for mode.
function! s:Buffer.mapping(mode, key, fn)
  let self.keymap[a:mode] = get(self.keymap, a:mode, [])
  call add(self.keymap[a:mode], a:key)
  call setbufvar(self.bufnr, printf('picka_buffer_keymap_%s_%s', a:mode, a:key), a:fn)
  if self.is_visible
    call self._remap()
  endif
endfunction

" remap all keymappings
function! s:Buffer._remap()
  if !self.is_visible
    return
  endif

  for [mode, maps] in items(self.keymap)
    let self.keymap[mode] = get(self.keymap, mode, [])
    for key in self.keymap[mode]
      execute printf('%s <silent><buffer>%s', { 'inoremap': 'iunmap', 'nnoremap': 'nunmap' }[mode], key)
      execute printf('%s <silent><buffer>%s :<C-u>call getbufvar(%s, "picka_buffer_keymap_%s_%s")()<CR>',
            \ mode,
            \ key,
            \ self.bufnr,
            \ mode,
            \ key)
    endfor
  endfor
endfunction

" --- Events

" BufWinEnter
function! s:Buffer.on_buf_win_enter()
  setlocal listchars=trail:\ 
  setlocal cursorline
  let self.is_visible = v:true
  let self.timer_id = timer_start(1000, function(self.on_tick), { 'repeat': -1 })
  call self._remap()
endfunction

" BufWinLeave
function! s:Buffer.on_buf_win_leave()
  let self.is_visible = v:false
  call timer_stop(get(self, 'timer_id', -1))
endfunction

" BufWipeout
function! s:Buffer.on_buf_wipeout()
  let self.is_visible = v:false
  call timer_stop(get(self, 'timer_id', -1))
  augroup printf('picka_buffer_%s', self.bufnr)
    autocmd!
  augroup END
endfunction

" CursorMoved
function! s:Buffer.on_cursor_moved()
  call self.check_state()
endfunction

" check buffer state changes
function! s:Buffer.on_tick(timer_id)
  call self.check_state()
endfunction

