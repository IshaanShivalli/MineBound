local BaseState = require 'src.states.BaseState'
local Grid = require 'src.world.Grid'
local Tile = require 'src.world.Tile'
local Hero = require 'src.entities.Hero'
local Core = require 'src.entities.Core'
local Minion = require 'src.entities.Minion'

PlayState = Class{__includes = BaseState}

local GRID_COLS = 20
local GRID_ROWS = 11
local TILE_SIZE = 32

function PlayState:init()
    self.grid = Grid(GRID_COLS, GRID_ROWS, TILE_SIZE)
    self.playerCore = Core(TILE_SIZE * 1, TILE_SIZE * 5, 'player', 400)
    self.enemyCore = Core(TILE_SIZE * (GRID_COLS - 2), TILE_SIZE * 5, 'enemy', 400)

    self.hero = Hero(TILE_SIZE * 3, TILE_SIZE * 5)
    self.minions = {}

    -- Visual Effects
    self.floatingTexts = {}
    self.sparks = {}
    self.slashes = {}
    self.lasers = {}

    self.gameOver = false
    self.gameTimer = 0
end

function PlayState:enter(params)
    params = params or {}
    if not params.resume then
        self:init()
    end
end

function PlayState:addFloatingText(x, y, text, color)
    table.insert(self.floatingTexts, {
        x = x,
        y = y,
        text = text,
        color = color or {1, 1, 1},
        opacity = 1.0,
        vy = -25,
        life = 0.8
    })
end

function PlayState:addSparks(x, y)
    for i = 1, 6 do
        local angle = math.random() * math.pi * 2
        local spd = math.random(30, 90)
        table.insert(self.sparks, {
            x = x,
            y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.25,
            color = {1, math.random(0.6, 0.9), 0.2}
        })
    end
end

function PlayState:addSlashEffect(x, y)
    table.insert(self.slashes, {
        x = x,
        y = y,
        life = 0.15,
        radius = 20
    })
end

function PlayState:addLaser(x1, y1, x2, y2, color)
    table.insert(self.lasers, {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        color = color,
        life = 0.12
    })
end

function PlayState:update(dt)
    if self.gameOver then return end
    self.gameTimer = self.gameTimer + dt

    -- Update Entities
    self.hero:update(dt, self.grid, self)
    self.grid:update(dt, self)
    self.playerCore:update(dt, self)
    self.enemyCore:update(dt, self)

    -- Update Minions
    for i = #self.minions, 1, -1 do
        local minion = self.minions[i]
        minion:update(dt, self)
        if not minion:isAlive() then
            self:addSparks(minion.x + minion.size / 2, minion.y + minion.size / 2)
            if minion.owner == 'enemy' then
                self.hero.gold = self.hero.gold + 5
                self:addFloatingText(minion.x, minion.y, "+5 Gold", {1, 0.8, 0.2})
            end
            table.remove(self.minions, i)
        end
    end

    -- Update Visual Effects
    for i = #self.floatingTexts, 1, -1 do
        local ft = self.floatingTexts[i]
        ft.life = ft.life - dt
        ft.y = ft.y + ft.vy * dt
        ft.opacity = ft.life / 0.8
        if ft.life <= 0 then
            table.remove(self.floatingTexts, i)
        end
    end

    for i = #self.sparks, 1, -1 do
        local sp = self.sparks[i]
        sp.life = sp.life - dt
        sp.x = sp.x + sp.vx * dt
        sp.y = sp.y + sp.vy * dt
        if sp.life <= 0 then
            table.remove(self.sparks, i)
        end
    end

    for i = #self.slashes, 1, -1 do
        local sl = self.slashes[i]
        sl.life = sl.life - dt
        if sl.life <= 0 then
            table.remove(self.slashes, i)
        end
    end

    for i = #self.lasers, 1, -1 do
        local lz = self.lasers[i]
        lz.life = lz.life - dt
        if lz.life <= 0 then
            table.remove(self.lasers, i)
        end
    end

    self:checkWinLossConditions()
end

function PlayState:checkWinLossConditions()
    if self.playerCore:isDestroyed() or not self.hero:isAlive() then
        self.gameOver = true
        gSounds['defeat']:play()
        gStateMachine:change('gameover', { won = false })
    elseif self.enemyCore:isDestroyed() then
        self.gameOver = true
        gSounds['victory']:play()
        gStateMachine:change('gameover', { won = true })
    end
end

function PlayState:keypressed(key)
    if key == 'escape' or key == 'p' then
        gStateMachine:change('pause', { previousState = self })
    elseif key == 'space' or key == 'k' then
        self.hero:mineOrBuild(self.grid, self)
    elseif key == 'j' or key == 'lctrl' then
        self.hero:attack(self)
    elseif key == '1' then
        self.hero.buildSelection = 'wall'
        self:addFloatingText(self.hero.x, self.hero.y - 12, "Build: Stone Wall (5 Stone)", {0.9, 0.9, 0.9})
    elseif key == '2' then
        self.hero.buildSelection = 'turret'
        self:addFloatingText(self.hero.x, self.hero.y - 12, "Build: Turret (25 Gold, 10 Stone)", {0.3, 0.8, 1})
    end
end

function PlayState:mousepressed(x, y, button)
    if button == 1 then
        self.hero:attack(self)
    elseif button == 2 then
        self.hero:mineOrBuild(self.grid, self)
    end
end

function PlayState:render()
    -- Render Tile Map
    self.grid:render()

    -- Render Target Indicator for Hero
    local tgx, tgy = self.hero:getTargetGridPosition(self.grid)
    local twx, twy = self.grid:gridToWorld(tgx, tgy)
    love.graphics.setColor(1, 1, 1, 0.4 + math.sin(love.timer.getTime() * 8) * 0.2)
    love.graphics.rectangle('line', twx, twy, TILE_SIZE, TILE_SIZE)
    love.graphics.setColor(1, 1, 1, 1)

    -- Render Cores
    self.playerCore:render()
    self.enemyCore:render()

    -- Render Minions
    for _, minion in ipairs(self.minions) do
        minion:render()
    end

    -- Render Hero
    self.hero:render()

    -- Render Lasers
    for _, lz in ipairs(self.lasers) do
        love.graphics.setColor(lz.color[1], lz.color[2], lz.color[3], lz.life / 0.12)
        love.graphics.setLineWidth(3)
        love.graphics.line(lz.x1, lz.y1, lz.x2, lz.y2)
        love.graphics.setLineWidth(1)
    end

    -- Render Slashes
    for _, sl in ipairs(self.slashes) do
        love.graphics.setColor(1, 1, 1, sl.life / 0.15)
        love.graphics.circle('line', sl.x, sl.y, sl.radius)
    end

    -- Render Sparks
    for _, sp in ipairs(self.sparks) do
        love.graphics.setColor(sp.color[1], sp.color[2], sp.color[3], sp.life / 0.25)
        love.graphics.rectangle('fill', sp.x, sp.y, 2, 2)
    end

    -- Render Floating Texts
    love.graphics.setFont(gFonts['small'])
    for _, ft in ipairs(self.floatingTexts) do
        love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], ft.opacity)
        love.graphics.printf(ft.text, ft.x - 40, ft.y, 80, 'center')
    end

    -- HUD Overlay (Top Bar)
    self:renderHUD()
end

function PlayState:renderHUD()
    -- Top Bar Background
    love.graphics.setColor(0.05, 0.07, 0.1, 0.85)
    love.graphics.rectangle('fill', 0, 0, push:getWidth(), 24)
    love.graphics.setColor(0.2, 0.25, 0.35, 1)
    love.graphics.line(0, 24, push:getWidth(), 24)

    -- Hero HP
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][1], 8, 4)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0.2, 0.9, 0.3, 1)
    love.graphics.print(self.hero.health .. '/' .. self.hero.maxHealth, 28, 4)

    -- Gold
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][2], 100, 4)
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.print(tostring(self.hero.gold), 120, 4)

    -- Stone
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][3], 170, 4)
    love.graphics.setColor(0.85, 0.85, 0.9, 1)
    love.graphics.print(tostring(self.hero.stone), 190, 4)

    -- Active Build Selection
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.7, 0.8, 0.9, 1)
    local buildText = (self.hero.buildSelection == 'wall') and '[1] Wall (5 Stone)' or '[2] Turret (25G, 10S)'
    love.graphics.print('Build [1/2]: ' .. buildText, 250, 6)

    -- Next Minion Wave Timer
    local waveTimeLeft = math.max(0, math.ceil(self.playerCore.spawnInterval - self.playerCore.spawnTimer))
    love.graphics.setColor(0.9, 0.9, 0.5, 1)
    love.graphics.print('Next Wave: ' .. waveTimeLeft .. 's', 460, 6)

    -- Bottom Controls Hint
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print('WASD: Move | J / L-Click: Attack | Space / K / R-Click: Mine/Build | 1/2: Select Build | Esc: Pause', 8, push:getHeight() - 14)
    love.graphics.setColor(1, 1, 1, 1)
end

return PlayState