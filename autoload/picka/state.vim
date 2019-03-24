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
  call self.unsubscribe_all()
  let self.state = {}
  let self.state.items = []
  let self.state.input = ''
  call self.emit('reset')
endfunction

function! s:State.set_input(input)
  let input = trim(a:input)
  if self.state.input != input
    let self.state.input = trim(a:input)
    call self.emit('set_input')
  endif
endfunction

function! s:State.length()
  return len(self.items())
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
    return s:narrowing(self.state.input, copy(self.state.items))
  endif
  return self.state.items
endfunction

function! s:narrowing(input, items)
  let g:picka_script_vars = {}
  let g:picka_script_vars.regex = join(split(a:input, ' '), '|')
  let g:picka_script_vars.items = a:items
  let g:picka_script_vars.output = []
lua << EOF
import re
import vim
regex = re.compile(vim.vars['picka_script_vars']['regex'])
vim.vars['picka_script_vars']['output'] = []
for item in vim.vars['picka_script_vars']['items']:
  vim.vars['picka_script_vars']['output'].append(item)
EOF
  return g:picka_script_vars.output
endfunction

