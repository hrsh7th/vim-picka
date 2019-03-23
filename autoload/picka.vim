let s:pickas = {}

function! picka#get(...)
  let name = len(a:000) ? a:000[0] : 'default'
  if !has_key(s:pickas, name)
    let s:pickas[name] = picka#new()
  endif
  return s:pickas[name]
endfunction

function! picka#new()
  let instance = extend(deepcopy(s:Picka), {})
  call instance.constructor()
  return instance
endfunction

let s:Picka = {}

function! s:Picka.constructor()
  let self.state = picka#state#new()
  let self.buffer = picka#buffer#new()
  let self.prompt = picka#prompt#new()
endfunction

function! s:Picka.start(callback)
  call self.state.reset()
  call self.buffer.reset()
  call self.prompt.reset()
  call self.state.subscribe('reset', function(self.on_redraw))
  call self.state.subscribe('add_item', function(self.on_redraw))
  call self.buffer.subscribe('reset', function(self.on_redraw))
  call self.buffer.subscribe('change_scope', function(self.on_redraw))
  call self.buffer.subscribe('buf_win_enter', function(self.on_redraw))
  call self.prompt.subscribe('reset', function(self.on_prompt_change))
  call self.prompt.subscribe('change', function(self.on_prompt_change))
  call self.buffer.mapping('nnoremap', 'i', function(self.on_start_insert, [0]))
  call self.buffer.mapping('nnoremap', 'a', function(self.on_start_insert, [1]))
  call timer_start(500, { -> a:callback(self) }, { 'repeat': 1 })
  return self
endfunction

function! s:Picka.open(opts)
  let opts = extend(a:opts, {
        \   'width': 12,
        \   'height': 12,
        \   'direction': 'botright'
        \ }, 'keep')
  execute printf('%s %snew', opts.direction, opts.height)
  execute printf('%sbuffer', self.buffer.bufnr)
endfunction

function! s:Picka.render()
  if !self.buffer.is_visible()
    return
  endif

  call self.buffer.modifiable(v:true)

  call self.buffer.set(self.state.length(), '')

  let scope = self.buffer.get_scope()
  for i in range(scope[0], max([scope[0], scope[1] - 1])) " `-1` for prompt.
    call self.buffer.set(i, get(self.state.items(), i - 1, { 'word': '' }).word)
  endfor

  call self.buffer.set(scope[1], self.prompt.text())

  silent! call matchdelete(self.highlights.prompt)
  if self.prompt.is_running
    let self.highlights.prompt = matchaddpos('Cursor', [[scope[1], self.prompt.get_col(), 1]])
    call cursor(scope[1], self.prompt.get_col())
  endif

  call self.buffer.modifiable(v:false)
endfunction

function! s:Picka.on_redraw()
  call self.render()
endfunction

function! s:Picka.on_start_insert(offset)
  let pos = line('.') == line('w$') ? self.prompt.col2pos(col('.') + a:offset) : self.prompt.max_pos()
  call self.prompt.start(pos)
endfunction

function! s:Picka.on_prompt_change()
  call self.state.set_input(join(self.prompt.input, ''))
  call self.render()
endfunction

