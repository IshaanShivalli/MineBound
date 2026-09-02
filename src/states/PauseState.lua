local BaseState = require 'src.states.BaseState'

PauseState = Class{__includes = BaseState}

function PauseState:init()
    self.previousState = nil
end

function PauseState:enter(params)
    params = params or {}
    self.previousState = params.previousState
end

function PauseState:keypressed(key)
    if key == 'escape' or key == 'p' or key == 'return' or key == 'kpenter' or key == 'space' then
        if self.previousState then
            gStateMachine.current = self.previousState
        else
            gStateMachine:change('play', { resume = true })
        end
    end
end

function PauseState:render()
    if self.previousState then
        self.previousState:render()
    end

    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, push:getWidth(), push:getHeight())

    -- Pause Text
    love.graphics.setFont(gFonts['large'])
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.printf('GAME PAUSED', 0, push:getHeight() / 2 - 30, push:getWidth(), 'center')

    -- Resume Prompt
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.8, 0.9, 1, 1)
    love.graphics.printf('Press Esc or P to Resume', 0, push:getHeight() / 2 + 10, push:getWidth(), 'center')

    love.graphics.setColor(1, 1, 1, 1)
end

return PauseState