local push = {}

local state = {
    gameWidth = 0,
    gameHeight = 0,
    windowWidth = 0,
    windowHeight = 0,
    scale = 1,
    xOffset = 0,
    yOffset = 0,
    canvas = nil,
    fullscreen = false,
}

function push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, settings)
    settings = settings or {}

    state.gameWidth = gameWidth
    state.gameHeight = gameHeight
    state.windowWidth = windowWidth
    state.windowHeight = windowHeight
    state.fullscreen = settings.fullscreen or false

    love.window.setMode(windowWidth, windowHeight, {
        fullscreen = state.fullscreen,
        vsync = settings.vsync == nil and true or settings.vsync,
        resizable = settings.resizable or false,
    })

    if settings.title then
        love.window.setTitle(settings.title)
    end

    state.scale = math.min(windowWidth / gameWidth, windowHeight / gameHeight)
    state.xOffset = (windowWidth - gameWidth * state.scale) / 2
    state.yOffset = (windowHeight - gameHeight * state.scale) / 2

    state.canvas = love.graphics.newCanvas(gameWidth, gameHeight)
    state.canvas:setFilter('nearest', 'nearest')

    return self
end

function push:apply(stage)
    if stage == 'start' then
        love.graphics.setCanvas(state.canvas)
        love.graphics.clear()
    elseif stage == 'end' then
        love.graphics.setCanvas()
        love.graphics.draw(
            state.canvas,
            state.xOffset,
            state.yOffset,
            0,
            state.scale,
            state.scale
        )
    end
end

function push:toGame(x, y)
    local gameX = (x - state.xOffset) / state.scale
    local gameY = (y - state.yOffset) / state.scale

    if gameX < 0 or gameX > state.gameWidth or gameY < 0 or gameY > state.gameHeight then
        return nil, nil
    end

    return gameX, gameY
end

function push:getWidth()
    return state.gameWidth
end

function push:getHeight()
    return state.gameHeight
end

return push