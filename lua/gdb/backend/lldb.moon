require "set_paths"
rex = require "rex_pcre"
BaseScm = require "gdb.scm"

r = rex.new                     -- construct a new matcher
m = (r, line) -> r\match(line)  -- matching function

--  lldb specifics

class LldbScm extends BaseScm
    new: (...) =>
        super select(2, ...)

        @addTrans(@paused, r([[^Process \d+ resuming]]),      m, @continue)
        @addTrans(@paused, r([[ at [\032]{2}([^:]+):(\d+)]]), m, @jump)
        @addTrans(@paused, r([[(lldb)]]),                     m, @pause)

        @addTrans(@running, r([[^Breakpoint \d+:]]),          m, @pause)
        @addTrans(@running, r([[^Process \d+ stopped]]),      m, @pause)
        @addTrans(@running, r([[(lldb)]]),                    m, @pause)

        @state = @running

backend =
    initScm: LldbScm
    delete_breakpoints: 'breakpoint delete'
    breakpoint: 'b'
    until: 'thread until'

backend
