local anim8 = {}

local Grid = {}
Grid.__index = Grid

function anim8.newGrid(frameWidth, frameHeight, imageWidth, imageHeight)
    local grid = setmetatable({}, Grid)
    grid.frameWidth = frameWidth
    grid.frameHeight = frameHeight
    grid.width = math.floor(imageWidth / frameWidth)
    grid.height = math.floor(imageHeight / frameHeight)
    return grid
end

local function parseRange(range)
    if type(range) == 'number' then
        return { range }
    end
    local result = {}
    local min, max = range:match("(%d+)%-(%d+)")
    if min and max then
        min, max = tonumber(min), tonumber(max)
        local step = min <= max and 1 or -1
        for i = min, max, step do
            table.insert(result, i)
        end
    else
        local num = tonumber(range)
        if num then
            table.insert(result, num)
        end
    end
    return result
end

function Grid:getFrames(...)
    local args = { ... }
    local frames = {}

    -- If called as getFrames('1-3', 1) or getFrames(1, 1, 2, 1) or getFrames('1-2', '1-2')
    if #args == 2 and (type(args[1]) == 'string' or type(args[2]) == 'string') then
        local cols = parseRange(args[1])
        local rows = parseRange(args[2])
        for _, row in ipairs(rows) do
            for _, col in ipairs(cols) do
                table.insert(frames, love.graphics.newQuad(
                    (col - 1) * self.frameWidth,
                    (row - 1) * self.frameHeight,
                    self.frameWidth,
                    self.frameHeight,
                    self.width * self.frameWidth,
                    self.height * self.frameHeight
                ))
            end
        end
        return frames
    end

    for i = 1, #args, 2 do
        local col, row = args[i], args[i + 1]
        table.insert(frames, love.graphics.newQuad(
            (col - 1) * self.frameWidth,
            (row - 1) * self.frameHeight,
            self.frameWidth,
            self.frameHeight,
            self.width * self.frameWidth,
            self.height * self.frameHeight
        ))
    end

    return frames
end

Grid.__call = Grid.getFrames

local Animation = {}
Animation.__index = Animation

function anim8.newAnimation(frames, durationPerFrame)
    local animation = setmetatable({}, Animation)
    animation.frames = frames
    animation.duration = durationPerFrame
    animation.timer = 0
    animation.currentFrame = 1
    return animation
end

function Animation:update(dt)
    self.timer = self.timer + dt
    if self.timer >= self.duration then
        self.timer = self.timer - self.duration
        self.currentFrame = self.currentFrame % #self.frames + 1
    end
end

function Animation:gotoFrame(frame)
    self.currentFrame = math.clamp(frame or 1, 1, #self.frames)
    self.timer = 0
end

function Animation:draw(image, x, y, r, sx, sy, ox, oy)
    love.graphics.draw(image, self.frames[self.currentFrame], x, y, r, sx, sy, ox, oy)
end

return anim8