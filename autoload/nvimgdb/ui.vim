
" Count of active debugging views
let g:nvimgdb_count = 0


function! s:GetExpression(...) range
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][:col2 - 1]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction


function! s:UndefCommands()
  delcommand GdbDebugStop
  delcommand GdbBreakpointToggle
  delcommand GdbBreakpointClearAll
  delcommand GdbRun
  delcommand GdbUntil
  delcommand GdbContinue
  delcommand GdbNext
  delcommand GdbStep
  delcommand GdbFinish
  delcommand GdbFrameUp
  delcommand GdbFrameDown
  delcommand GdbInterrupt
  delcommand GdbEvalWord
  delcommand GdbEvalRange
endfunction

function! s:DefineCommands()
  command! GdbDebugStop call nvimgdb#Kill()
  command! GdbBreakpointToggle lua gdb.toggleBreak()
  command! GdbBreakpointClearAll lua gdb.clearBreaks()
  command! GdbRun lua gdb.send('run')
  command! GdbUntil call luaeval("gdb.send(gdb.getCommand('until') .. ' ' .. _A)", line('.'))
  command! GdbContinue lua gdb.send('c')
  command! GdbNext lua gdb.send('n')
  command! GdbStep lua gdb.send('s')
  command! GdbFinish lua gdb.send('finish')
  command! GdbFrameUp lua gdb.send('up')
  command! GdbFrameDown lua gdb.send('down')
  command! GdbInterrupt lua gdb.interrupt()
  command! GdbEvalWord call luaeval("gdb.send(_A)", 'print ' . expand('<cword>'))
  command! -range GdbEvalRange call luaeval("gdb.send(_A)", 'print ' . s:GetExpression(<f-args>))
endfunction


function! nvimgdb#ui#Leave()
  let g:nvimgdb_count -= 1
  if !g:nvimgdb_count
    " Cleanup the autocommands
    augroup NvimGdb
      au!
    augroup END
    augroup! NvimGdb

    " Cleanup user commands and keymaps
    call s:UndefCommands()
  endif
endfunction

function! nvimgdb#ui#Enter()
  if !g:nvimgdb_count
    call s:DefineCommands()
    augroup NvimGdb
      au!
      " Unfortunately, there is no event to handle a window closed.
      " It's needed to be handled heuristically:
      "   When :quit is executed, the cursor will enter another buffer
      au WinEnter * call nvimgdb#CheckWindowClosed()
      "   When :only is executed, BufWinLeave will be issued before closing
      "   window. We start a timer expecting it to expire after the window
      "   has been closed. It's a race.
      au BufWinLeave * call timer_start(100, "nvimgdb#CheckWindowClosed")
      au TabEnter * lua gdb.tabEnter()
      au TabLeave * lua gdb.tabLeave()
      au BufEnter * lua gdb.onBufEnter()
      au BufLeave * lua gdb.onBufLeave()
    augroup END
  endif
  let g:nvimgdb_count += 1
endfunction
