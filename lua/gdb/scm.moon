
-- Abstract interface for a debugger state machine
class Scm
    isPaused: => assert(nil, "Not implemented")     -- is the inferior paused?
    isRunning: => assert(nil, "Not implemented")    -- is the inferior running?
    feed: (line) => assert(nil, "Not implemented")  -- process a single line

-- Common SCM implementation for the integrated backends
class BaseScm extends Scm
    new: (cursor, win, trace) =>
        assert cursor.__class.__name == "Cursor"
        assert win.__class.__name == "Win"
        assert trace.__class.__name == "Trace"
        @cursor = cursor
        @win = win
        @trace = trace

        @running = {}   -- The running state {{matcher, matchingFunc, handler}}
        @paused = {}    -- The paused state {{matcher, matchingFunc, handler}}
        @state = nil    -- Current state (either @running or @paused)

    -- Add a new transition for a given state using {matcher, matchingFunc}
    -- Call the handler when matched.
    addTrans: (state, matcher, func, handler) =>
        state[#state + 1] = {matcher, func, handler}

    -- Transition "paused" -> "continue"
    continue: (...) =>
        @state = @running
        @cursor\hide()
        @trace\log("continue")

    -- Transition "paused" -> "paused": jump to the frame location
    jump: (file, line, ...) =>
        @win\jump(file, line)
        @trace\log("jump")

    -- Transition <any> -> "pause"
    pause: (...) =>
        @state = @paused
        @win\queryBreakpoints!
        @trace\log("pause")

    isPaused: =>
        @state == @paused

    isRunning: =>
        @state == @running

    -- Process a line of the debugger output through the SCM.
    feed: (line) =>
        -- If there is a matcher matching the line, call its handler.
        for _, v in ipairs(@state)
            matcher, func, handler = unpack(v)
            m1, m2 = func(matcher, line)
            if m1
                handler(@, m1, m2)
                break


BaseScm
