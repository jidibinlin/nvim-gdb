class Trace
    maxSize: 10

    new: =>
        @events = {}
        @curIdx = 1

    log: (event) =>
        if #@events == maxSize
            @events[@curIdx - maxSize] = nil
        @events[@curIdx] = event
        @curIdx += 1

    get: =>
        @events, @curIdx - 1

    getLast: =>
        @events[@curIdx - 1]
