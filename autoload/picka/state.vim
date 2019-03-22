let s:Event = picka#event#get()

function! picka#state#new()
  let instance = extend(deepcopy(s:State), s:Event)
  call instance.constructor()
  return instance
endfunction

let s:State = {}

function! s:State.constructor()
  call self.reset()
endfunction

function! s:State.reset()
  let self.is_running = v:false
  let self.state = {}
  let self.state.items = []
  let self.state.input = ''
endfunction

function! s:State.start()
  let self.is_running = v:true
  call self.emit('start')
endfunction

function! s:State.finish()
  let self.is_running = v:false
  call self.emit('finish')
endfunction

function! s:State.set_input(input)
  let self.state.input = trim(a:input)
  call self.emit('set_input')
endfunction

function! s:State.length()
  return len(self.state.items)
endfunction

function! s:State.add_item(item)
  call add(self.state.items, a:item)
  call self.emit('add_item')
endfunction

function! s:State.add_item_at(item, idx)
  call insert(self.state.items, a:item, a:idx)
  call self.emit('add_item')
endfunction

function! s:State.items()
  if strlen(self.state.input) > 0
    return s:narrowing(self.state.input, self.state.items)
  endif
  return self.state.items
endfunction

function! s:narrowing(input, items)
  let regex = join(split(a:input, ' '), '\|')
  return filter(copy(a:items), { k, v -> match(v.word, regex) >= 0 })
endfunction

