local BaseState = require 'src.states.BaseState'

GameOverState = Class{__includes = BaseState}

function GameOverState:init()
    self.resultText = ''
    self.promptText = 'PRESS ENTER TO RETURN TO TITLE'
    self.won = false
end

function GameOverState:enter(params)
    params = params or {}
    self.won = params.won or false
    if self.won then
        self.resultText = 'VICTORY!'
    else
        self.resultText = 'DEFEAT'
    end
end

function GameOverState:keypressed(key)
    if key == 'return' or key == 'kpenter' or key == 'space' then
        gStateMachine:change('title')
    end
end

function GameOverState:render()
    -- Overlay
    love.graphics.setColor(0.04, 0.05, 0.08, 0.95)
    love.graphics.rectangle('fill', 0, 0, push:getWidth(), push:getHeight())

    -- Result Text
    love.graphics.setFont(gFonts['title'])
    if self.won then
        love.graphics.setColor(0.2, 0.9, 0.3, 1)
        love.graphics.printf(self.resultText, 0, push:getHeight() / 2 - 50, push:getWidth(), 'center')
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(1, 0.85, 0.2, 1)
        love.graphics.printf('Enemy Nexus Destroyed! The Realm is Saved.', 0, push:getHeight() / 2, push:getWidth(), 'center')
    else
        love.graphics.setColor(0.95, 0.25, 0.25, 1)
        love.graphics.printf(self.resultText, 0, push:getHeight() / 2 - 50, push:getWidth(), 'center')
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.printf('Your Nexus was Overrun by Enemies.', 0, push:getHeight() / 2, push:getWidth(), 'center')
    end

    -- Return Prompt
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.7, 0.75, 0.85, 1)
    love.graphics.printf(self.promptText, 0, push:getHeight() / 2 + 50, push:getWidth(), 'center')
    love.graphics.setColor(1, 1, 1, 1)
end

return GameOverState