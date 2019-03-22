let s:Event = picka#event#get()

function! picka#prompt#new()
  let instance = extend(deepcopy(s:Prompt), s:Event)
  call instance.constructor()
  return instance
endfunction

let s:Prompt = {}

function! s:Prompt.constructor()
  let self.input = []
  let self.pos = 0
  let self.is_running = v:false
  let self.prompt = '> '
endfunction

function! s:Prompt.running(v)
  let self.is_running = a:v ? v:true : v:false
endfunction

function! s:Prompt.start(pos)
  let self.pos = a:pos
  call self.running(v:true)
  while v:true
    call self.emit('change')
    redraw

    call self.running(v:false)
    let char = getchar()
    if "\<Esc>" ==# nr2char(char)
      call self.escape()
      break
    endif
    call self.running(v:true)

    if "\<BS>" ==# char || "\<Del>" ==# char
      if self.pos > 0
        call self.backspace()
      endif
    elseif "\<Left>" ==# char
      call self.left()
    elseif "\<Right>" ==# char
      call self.right()
    elseif 'h' ==# nr2char(char) && getcharmod() == 4
      call self.left()
    elseif 'l' ==# nr2char(char) && getcharmod() == 4
      call self.right()
    else
      call insert(self.input, nr2char(char), self.pos)
      call self.right()
    endif
  endwhile
endfunction

function! s:Prompt.reset()
  let self.input = []
  let self.pos = 0
  let self.is_running = v:false
endfunction

function! s:Prompt.get_col()
  return self.pos + strlen(self.prompt) + 1
endfunction

function! s:Prompt.col2pos(col)
  let col = max([self.min_col(), min([self.max_col(), a:col])])
  return col - strlen(self.prompt) - 1
endfunction

function! s:Prompt.max_pos()
  return strlen(self.text()) - strlen(self.prompt)
endfunction

function! s:Prompt.max_col()
  return strlen(self.prompt . join(self.input, '') . ' ')
endfunction

function! s:Prompt.min_col()
  return strlen(self.prompt) + 1
endfunction

function! s:Prompt.text()
  let text = join(self.input, '')
  if strlen(text) == self.pos && self.is_running
    return self.prompt . text . ' ' " show cursor shape
  endif
  return self.prompt . text
endfunction

function! s:Prompt.escape()
  redraw
endfunction

function! s:Prompt.backspace()
  call remove(self.input, self.pos - 1)
  call self.left()
endfunction

function! s:Prompt.left()
  let self.pos = max([self.pos - 1, 0])
endfunction

function! s:Prompt.right()
  let self.pos = min([self.pos + 1, len(self.input)])
endfunction

