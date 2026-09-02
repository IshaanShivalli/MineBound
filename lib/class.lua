--
-- class.lua
-- Compatible with CS50 / HUMP Class library
--
local function include_helper(to, from, seen)
    if from == nil then
        return to
    elseif type(from) ~= 'table' then
        return from
    elseif seen[from] then
        return seen[from]
    end

    seen[from] = to
    for k, v in pairs(from) do
        if k ~= '__index' then
            if type(v) == 'table' then
                to[k] = include_helper({}, v, seen)
            else
                to[k] = v
            end
        end
    end
    return to
end

local function include(class, other)
    return include_helper(class, other, {})
end

local function clone(other)
    return include({}, other)
end

local function new(class)
    local inc = class.__includes or class.includes
    local match = {}
    if inc then
        if type(inc) == 'table' then
            if inc[1] then
                for _, other in ipairs(inc) do
                    include(match, other)
                end
            else
                include(match, inc)
            end
        else
            include(match, inc)
        end
    end
    include(match, class)
    match.__index = match

    local mt = {}
    mt.__call = function(_, ...)
        local obj = setmetatable({}, match)
        if obj.init then
            obj:init(...)
        end
        return obj
    end

    return setmetatable(match, mt)
end

return setmetatable({ new = new, include = include, clone = clone }, {
    __call = function(_, ...) return new(...) end
})
