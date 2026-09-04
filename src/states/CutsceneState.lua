local BaseState = require 'src.states.BaseState'

CutsceneState = Class{__includes = BaseState}

function CutsceneState:init()
    self.scenes = {
        {
            title = "ACT I: THE FRACTURED TWIN REALMS",
            text = "For millennia, the Surface Realm and the Nether Void existed in delicate equilibrium.\n\nThen, the Ancient Nexus fractured—spilling raw dimensional energy across both worlds.",
            color = {0.3, 0.7, 1.0},
            subtext = "Press SPACE / ENTER to continue"
        },
        {
            title = "ACT II: THE NETHER ANCHOR & THE CRUMBLING CORE",
            text = "The enemy forces established a Nether Anchor in the Underworld,\nchanneling a protective dimensional shield over their Surface Nexus.\n\nDirect attacks on their fortress are futile as long as the Anchor stands.",
            color = {0.9, 0.4, 1.0},
            subtext = "Press SPACE / ENTER to continue"
        },
        {
            title = "ACT III: YOUR MISSION",
            text = "Shift between dimensions (Q / Shift). Harvest Surface Gold and Nether Gems.\nSlay the ancient Void Golem for team fury, destroy the enemy Nether Anchor,\nand obliterate the enemy Nexus to claim ultimate victory.",
            color = {1.0, 0.85, 0.2},
            subtext = "PRESS ENTER TO ENTER THE BATTLEFIELD"
        }
    }
    self.currentScene = 1
    self.fadeAlpha = 0
    self.fadeIn = true
    self.timer = 0
end

function CutsceneState:enter(params)
    self.currentScene = 1
    self.fadeAlpha = 0
    self.fadeIn = true
    self.timer = 0
end

function CutsceneState:update(dt)
    self.timer = self.timer + dt

    if self.fadeIn then
        self.fadeAlpha = math.min(1.0, self.fadeAlpha + dt * 2.0)
    else
        self.fadeAlpha = math.max(0.0, self.fadeAlpha - dt * 3.0)
        if self.fadeAlpha <= 0 then
            self.currentScene = self.currentScene + 1
            if self.currentScene > #self.scenes then
                gStateMachine:change('play')
                return
            end
            self.fadeIn = true
        end
    end
end

function CutsceneState:keypressed(key)
    if key == 'return' or key == 'kpenter' or key == 'space' then
        gSounds['build']:stop()
        gSounds['build']:play()
        self.fadeIn = false
    elseif key == 'escape' then
        -- Skip cutscene directly to play
        gStateMachine:change('play')
    end
end

function CutsceneState:render()
    local scene = self.scenes[self.currentScene]
    if not scene then return end

    -- Letterbox Cinematic Background
    love.graphics.setColor(0.03, 0.04, 0.07, 1)
    love.graphics.rectangle('fill', 0, 0, push:getWidth(), push:getHeight())

    -- Top & Bottom Black Letterbox Bars
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('fill', 0, 0, push:getWidth(), 35)
    love.graphics.rectangle('fill', 0, push:getHeight() - 35, push:getWidth(), 35)

    -- Ambient Floating Particle Dust & Moving Cutscene Actors
    love.graphics.setColor(scene.color[1], scene.color[2], scene.color[3], 0.15 * self.fadeAlpha)
    for i = 1, 25 do
        local px = (math.sin(self.timer * 0.5 + i * 2.3) * 0.5 + 0.5) * push:getWidth()
        local py = (math.cos(self.timer * 0.4 + i * 1.7) * 0.5 + 0.5) * (push:getHeight() - 80) + 40
        love.graphics.circle('fill', px, py, 2)
    end

    -- Moving Cutscene Sprites / Animation
    local actorX = ((self.timer * 60) % (push:getWidth() + 80)) - 40
    local actorY = push:getHeight() - 75
    love.graphics.setColor(1, 1, 1, self.fadeAlpha * 0.95)
    love.graphics.draw(gTextures['hero'], gFrames['hero'][2], actorX, actorY)

    local minionX = actorX - 45
    love.graphics.draw(gTextures['minion_player'], gFrames['minion_player'][1], minionX, actorY + 4)

    local portalPulse = (math.sin(self.timer * 5) + 1) * 0.5
    love.graphics.setColor(0.8, 0.3, 1.0, self.fadeAlpha * (0.3 + portalPulse * 0.3))
    love.graphics.circle('fill', push:getWidth() - 80, push:getHeight() / 2, 30 + portalPulse * 10)
    love.graphics.setColor(0.9, 0.6, 1.0, self.fadeAlpha * 0.8)
    love.graphics.circle('line', push:getWidth() - 80, push:getHeight() / 2, 35 + portalPulse * 10)

    -- Scene Content with Fade
    love.graphics.setColor(scene.color[1], scene.color[2], scene.color[3], self.fadeAlpha)
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf(scene.title, 0, 55, push:getWidth(), 'center')

    love.graphics.setColor(0.9, 0.95, 1.0, self.fadeAlpha * 0.9)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf(scene.text, 40, 115, push:getWidth() - 80, 'center')

    -- Prompt / Skip Hint
    local pulse = (math.sin(self.timer * 6) + 1) * 0.5
    love.graphics.setColor(1, 1, 1, self.fadeAlpha * (0.5 + pulse * 0.5))
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf(scene.subtext, 0, push:getHeight() - 55, push:getWidth(), 'center')

    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.printf("ESC to Skip", push:getWidth() - 100, 12, 90, 'right')
    love.graphics.setColor(1, 1, 1, 1)
end

return CutsceneState
