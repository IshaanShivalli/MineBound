local BaseState = require 'src.states.BaseState'

TitleState = Class{__includes = BaseState}

function TitleState:init()
    self.titleText = 'MINEBOUND'
    self.promptText = 'PRESS ENTER TO START'
    self.promptTimer = 0
    self.showPrompt = true

    -- Mini hero preview animation on title screen
    local g = anim8.newGrid(24, 24, gTextures['hero']:getWidth(), gTextures['hero']:getHeight())
    self.heroAnim = anim8.newAnimation(g('2-3', 1), 0.15)
end

function TitleState:enter(params)
    self.promptTimer = 0
    self.showPrompt = true
end

function TitleState:update(dt)
    self.promptTimer = self.promptTimer + dt
    if self.promptTimer >= 0.5 then
        self.promptTimer = 0
        self.showPrompt = not self.showPrompt
    end

    self.heroAnim:update(dt)
end

function TitleState:keypressed(key)
    if key == 'return' or key == 'kpenter' or key == 'space' then
        gSounds['mine']:play()
        gStateMachine:change('play')
    elseif key == 'escape' then
        love.event.quit()
    end
end

function TitleState:render()
    -- Deep Starry Arena Background
    love.graphics.setColor(0.08, 0.10, 0.14, 1)
    love.graphics.rectangle('fill', 0, 0, push:getWidth(), push:getHeight())

    -- Decorative Grid Pattern
    love.graphics.setColor(1, 1, 1, 0.05)
    for x = 0, push:getWidth(), 32 do
        love.graphics.line(x, 0, x, push:getHeight())
    end
    for y = 0, push:getHeight(), 32 do
        love.graphics.line(0, y, push:getWidth(), y)
    end

    -- Title Banner
    love.graphics.setFont(gFonts['title'])
    love.graphics.setColor(0.1, 0.5, 0.9, 0.5)
    love.graphics.printf(self.titleText, 2, push:getHeight() / 2 - 88, push:getWidth(), 'center')
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.printf(self.titleText, 0, push:getHeight() / 2 - 90, push:getWidth(), 'center')

    -- Subtitle
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0.8, 0.9, 1, 1)
    love.graphics.printf('2D Hero MOBA & Tile Mining Defense', 0, push:getHeight() / 2 - 45, push:getWidth(), 'center')

    -- Animated Hero Sprite preview
    love.graphics.setColor(1, 1, 1, 1)
    self.heroAnim:draw(gTextures['hero'], push:getWidth() / 2 - 24, push:getHeight() / 2 - 15, 0, 2, 2)

    -- Instructions
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.7, 0.75, 0.85, 1)
    love.graphics.printf('WASD: Move | J / L-Click: Slash Attack | Space / K / R-Click: Mine & Build | 1/2: Select Defense', 0, push:getHeight() / 2 + 50, push:getWidth(), 'center')

    -- Start Prompt
    if self.showPrompt then
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(0.3, 1, 0.4, 1)
        love.graphics.printf(self.promptText, 0, push:getHeight() / 2 + 80, push:getWidth(), 'center')
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return TitleState