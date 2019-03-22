let s:pickas = {}

function! picka#run(callback, ...)
  let name = len(a:000) ? a:000[0] : 'default'
  if !has_key(s:pickas, name)
    let s:pickas[name] = picka#new()
  endif
  return s:pickas[name].run(a:callback)
endfunction

function! picka#new()
  let instance = extend(deepcopy(s:Picka), {})
  call instance.constructor()
  return instance
endfunction

let s:Picka = {}

function! s:Picka.constructor()
  let self.buffer = picka#buffer#new()
  let self.state = picka#state#new()
  let self.prompt = picka#prompt#new()
  let self.highlights = {}
  let self.highlights.prompt = -1
  call self.state.subscribe('reset', function(self.on_redraw))
  call self.state.subscribe('add_item', function(self.on_redraw))
  call self.state.subscribe('set_input', function(self.on_redraw))
  call self.buffer.subscribe('reset', function(self.on_redraw))
  call self.buffer.subscribe('change_scope', function(self.on_redraw))
  call self.buffer.subscribe('buf_win_enter', function(self.on_redraw))
  call self.prompt.subscribe('reset', function(self.on_prompt_change))
  call self.prompt.subscribe('change', function(self.on_prompt_change))
  call self.buffer.mapping('nnoremap', 'i', function(self.on_start_insert, [0]))
  call self.buffer.mapping('nnoremap', 'a', function(self.on_start_insert, [1]))
endfunction

" run
function! s:Picka.run(callback)
  call self.buffer.reset()
  call self.state.reset()
  call self.prompt.reset()
  call a:callback(self)
  return self
endfunction

" open
function! s:Picka.open(opts)
  let opts = extend(a:opts, {
        \   'width': 12,
        \   'height': 12,
        \   'direction': 'botright'
        \ }, 'keep')
  execute printf('%s %snew', opts.direction, opts.height)
  execute printf('%sbuffer', self.buffer.bufnr)
endfunction

" render
function! s:Picka.render()
  if !self.buffer.is_visible
    return
  endif

  " remove current highlights
  silent! call matchdelete(self.highlights.prompt)

  " modifiable: true
  call self.buffer.modifiable(v:true)

  " buffer height.
  call self.buffer.set(self.state.length(), '')

  " render lines
  let scope = self.buffer.get_scope()
  for i in range(scope[0], max([scope[0], scope[1] - 1])) " `-1` for prompt.
    call self.buffer.set(i, get(self.state.items(), i - 1, { 'word': '' }).word)
  endfor

  " render prompt
  call self.buffer.set(scope[1], self.prompt.text())

  " show prompt cursor
  if self.prompt.is_running
    let self.highlights.prompt = matchaddpos('Cursor', [[scope[1], self.prompt.get_col(), 1]])
    call cursor(scope[1], self.prompt.get_col())
  endif

  " modifiable: false
  call self.buffer.modifiable(v:false)
endfunction

" on_redraw
function! s:Picka.on_redraw()
  call self.render()
endfunction

" on_start_insert, offset for `i` or `a`
function! s:Picka.on_start_insert(offset)
  let pos = line('.') == line('w$') ? self.prompt.col2pos(col('.') + a:offset) : self.prompt.max_pos()
  call self.prompt.start(pos)
endfunction

function! s:Picka.on_prompt_change()
  call self.state.set_input(join(self.prompt.input, ''))
endfunction

