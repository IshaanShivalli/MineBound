--
-- knife.event
--
local event = {}

local handlers = {}

function event.on(name, fn)
    handlers[name] = handlers[name] or {}
    table.insert(handlers[name], fn)
    return fn
end

function event.dispatch(name, ...)
    if not handlers[name] then return end
    for _, fn in ipairs(handlers[name]) do
        fn(...)
    end
end

function event.clear(name)
    if name then
        handlers[name] = nil
    else
        handlers = {}
    end
end

return event
