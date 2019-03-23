let s:Event = picka#event#get()

function! picka#prompt#new()
  let instance = extend(deepcopy(s:Prompt), s:Event)
  call instance.constructor()
  return instance
endfunction

let s:Prompt = {}

function! s:Prompt.constructor()
  call self.reset()
endfunction

function! s:Prompt.reset()
  call self.unsubscribe_all()
  let self.input = []
  let self.pos = 0
  let self.is_running = v:false
  let self.prompt = '> '
  let self.highlight = -1
  call self.emit('reset')
endfunction

function! s:Prompt.start(pos)
  let self.pos = a:pos
  while v:true
    let self.is_running = v:true
    call self.emit('change')
    redraw

    let self.is_running = v:false
    let char = getchar()
    if "\<Esc>" ==# nr2char(char)
      call self.escape()
      break
    endif
    let self.is_running = v:true

    if "\<BS>" ==# char || "\<Del>" ==# char
      if self.pos > 0
        call self.backspace()
      endif
    elseif "\<Left>" ==# char
      call self.on_left()
    elseif "\<Right>" ==# char
      call self.on_right()
    elseif "\<C-h>" ==# nr2char(char)
      call self.on_left()
    elseif "\<C-l>" ==# nr2char(char)
      call self.on_right()
    else
      call insert(self.input, nr2char(char), self.pos)
      call self.on_right()
    endif
  endwhile
endfunction

function! s:Prompt.get_col()
  return self.pos + strlen(self.prompt) + 1
endfunction

function! s:Prompt.col2pos(col)
  let col = max([self.min_col(), min([self.max_col(), a:col])])
  return col - strlen(self.prompt) - 1
endfunction

function! s:Prompt.max_pos()
  return strlen(self.text()) - strlen(self.prompt) - 1
endfunction

function! s:Prompt.max_col()
  return strlen(self.text())
endfunction

function! s:Prompt.min_col()
  return strlen(self.prompt) + 1
endfunction

function! s:Prompt.text()
  return self.prompt . join(self.input, '') . ' '
endfunction

function! s:Prompt.on_escape()
  redraw
endfunction

function! s:Prompt.on_backspace()
  call remove(self.input, self.pos - 1)
  call self.left()
endfunction

function! s:Prompt.on_left()
  let self.pos = max([self.pos - 1, 0])
endfunction

function! s:Prompt.on_right()
  let self.pos = min([self.pos + 1, len(self.input)])
endfunction

