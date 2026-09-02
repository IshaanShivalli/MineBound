local BaseState = require 'src.states.BaseState'
local Grid = require 'src.world.Grid'
local Tile = require 'src.world.Tile'
local Hero = require 'src.entities.Hero'
local Core = require 'src.entities.Core'
local Minion = require 'src.entities.Minion'
local EnemyAI = require 'src.entities.EnemyAI'

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
    self.enemyAI = EnemyAI(self)

    -- Visual Effects (dimension-tagged)
    self.floatingTexts = {}
    self.sparks = {}
    self.slashes = {}
    self.lasers = {}

    -- Dimension Transition FX
    self.shiftTransitionTimer = 0
    self.shiftTransitionMax = 0.35
    self.currentRenderDim = 'overworld'
    self.riftNearby = false

    self.gameOver = false
    self.gameTimer = 0
end

function PlayState:enter(params)
    params = params or {}
    if not params.resume then
        self:init()
    end
end

function PlayState:triggerDimensionShift(targetDim)
    self.shiftTransitionTimer = self.shiftTransitionMax
    self.currentRenderDim = targetDim

    -- Spawn dimensional warp sparkles around hero
    for i = 1, 14 do
        local angle = math.random() * math.pi * 2
        local spd = math.random(50, 140)
        table.insert(self.sparks, {
            x = self.hero.x + self.hero.width / 2,
            y = self.hero.y + self.hero.height / 2,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.4,
            dimension = targetDim,
            color = (targetDim == 'nether') and {0.9, 0.3, 1} or {0.3, 0.9, 1}
        })
    end
end

function PlayState:addFloatingText(x, y, text, color, dimension)
    table.insert(self.floatingTexts, {
        x = x,
        y = y,
        text = text,
        color = color or {1, 1, 1},
        dimension = dimension or self.hero.dimension,
        opacity = 1.0,
        vy = -25,
        life = 0.8
    })
end

function PlayState:addSparks(x, y, color, dimension)
    for i = 1, 6 do
        local angle = math.random() * math.pi * 2
        local spd = math.random(30, 90)
        table.insert(self.sparks, {
            x = x,
            y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.25,
            dimension = dimension or self.hero.dimension,
            color = color or {1, math.random(0.6, 0.9), 0.2}
        })
    end
end

function PlayState:addSlashEffect(x, y, dimension)
    table.insert(self.slashes, {
        x = x,
        y = y,
        dimension = dimension or self.hero.dimension,
        life = 0.15,
        radius = 20
    })
end

function PlayState:addLaser(x1, y1, x2, y2, color, dimension)
    table.insert(self.lasers, {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        color = color,
        dimension = dimension or 'overworld',
        life = 0.12
    })
end

function PlayState:update(dt)
    if self.gameOver then return end
    self.gameTimer = self.gameTimer + dt

    if self.shiftTransitionTimer > 0 then
        self.shiftTransitionTimer = self.shiftTransitionTimer - dt
    end

    -- Update Entities
    self.hero:update(dt, self.grid, self)
    self.grid:update(dt, self)
    self.playerCore:update(dt, self)
    self.enemyCore:update(dt, self)
    self.enemyAI:update(dt)

    -- Update Minions across both dimensions
    for i = #self.minions, 1, -1 do
        local minion = self.minions[i]
        minion:update(dt, self)
        if not minion:isAlive() then
            self:addSparks(minion.x + minion.size / 2, minion.y + minion.size / 2, (minion.dimension == 'nether') and {0.9, 0.4, 1} or {1, 0.8, 0.2}, minion.dimension)
            if minion.owner == 'enemy' then
                if minion.dimension == 'nether' then
                    self.hero.voidEssence = self.hero.voidEssence + 8
                    self:addFloatingText(minion.x, minion.y, "+8 Gems", {0.9, 0.4, 1.0}, 'nether')
                else
                    self.hero.gold = self.hero.gold + 5
                    self:addFloatingText(minion.x, minion.y, "+5 Coins", {1, 0.8, 0.2}, 'overworld')
                end
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
    elseif key == 'q' or key == 'lshift' or key == 'rshift' then
        self.hero:shiftDimension(self.grid, self)
    elseif key == '1' then
        self.hero.buildSelection = 'wall'
        local wallName = (self.hero.dimension == 'nether') and "Obsidian Wall (5 Ores)" or "Stone Wall (5 Ores)"
        self:addFloatingText(self.hero.x, self.hero.y - 12, "Build: " .. wallName, {0.9, 0.9, 0.9}, self.hero.dimension)
    elseif key == '2' then
        self.hero.buildSelection = 'turret'
        self:addFloatingText(self.hero.x, self.hero.y - 12, "Build: Laser Turret (25 Coins, 10 Ores)", {0.3, 0.8, 1}, self.hero.dimension)
    elseif key == '3' then
        self.hero.buildSelection = 'anchor'
        self:addFloatingText(self.hero.x, self.hero.y - 12, "Build: Void Anchor (30 Gems, 20 Coins)", {0.9, 0.4, 1.0}, self.hero.dimension)
    elseif key == '4' then
        self.hero.buildSelection = 'healer'
        self:addFloatingText(self.hero.x, self.hero.y - 12, "Build: Healing Chamber (50 Coins, 60 Ores, 20 Gems)", {0.2, 1.0, 0.5}, self.hero.dimension)
    end
end

function PlayState:mousepressed(x, y, button)
    if button == 1 then
        self.hero:attack(self)
    elseif button == 2 then
        self.hero:mineOrBuild(self.grid, self)
    elseif button == 3 then
        self.hero:shiftDimension(self.grid, self)
    end
end

function PlayState:render()
    local curDim = self.hero.dimension

    -- Render Active Dimension Tile Map
    self.grid:render(curDim)

    -- In Nether Realm: Draw atmospheric void overlay
    if curDim == 'nether' then
        love.graphics.setColor(0.2, 0.05, 0.35, 0.18)
        love.graphics.rectangle('fill', 0, 0, push:getWidth(), push:getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Render Target Indicator for Hero
    local tgx, tgy = self.hero:getTargetGridPosition(self.grid)
    local twx, twy = self.grid:gridToWorld(tgx, tgy)
    love.graphics.setColor(1, 1, 1, 0.4 + math.sin(love.timer.getTime() * 8) * 0.2)
    love.graphics.rectangle('line', twx, twy, TILE_SIZE, TILE_SIZE)
    love.graphics.setColor(1, 1, 1, 1)

    -- Render Cores (if in Overworld, or ghosted silhouette if in Nether)
    if curDim == 'overworld' then
        self.playerCore:render(self)
        self.enemyCore:render(self)
    else
        -- Ghost indicator in Nether of where Overworld cores are
        love.graphics.setColor(0.3, 0.7, 1.0, 0.25)
        love.graphics.rectangle('line', self.playerCore.x, self.playerCore.y, 32, 32)
        love.graphics.setColor(1.0, 0.3, 0.3, 0.25)
        love.graphics.rectangle('line', self.enemyCore.x, self.enemyCore.y, 32, 32)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Render Minions only in current dimension
    for _, minion in ipairs(self.minions) do
        if minion.dimension == curDim then
            minion:render()
        end
    end

    -- Render Hero
    self.hero:render()

    -- Render Lasers strictly matching the active realm
    for _, lz in ipairs(self.lasers) do
        if lz.dimension == curDim then
            love.graphics.setColor(lz.color[1], lz.color[2], lz.color[3], lz.life / 0.12)
            love.graphics.setLineWidth(3)
            love.graphics.line(lz.x1, lz.y1, lz.x2, lz.y2)
            love.graphics.setLineWidth(1)
        end
    end

    -- Render Slashes strictly matching the active realm
    for _, sl in ipairs(self.slashes) do
        if sl.dimension == curDim then
            love.graphics.setColor(1, 1, 1, sl.life / 0.15)
            love.graphics.circle('line', sl.x, sl.y, sl.radius)
        end
    end

    -- Render Sparks strictly matching the active realm
    for _, sp in ipairs(self.sparks) do
        if sp.dimension == curDim then
            love.graphics.setColor(sp.color[1], sp.color[2], sp.color[3], sp.life / 0.25)
            love.graphics.rectangle('fill', sp.x, sp.y, 2, 2)
        end
    end

    -- Render Floating Texts strictly matching the active realm
    love.graphics.setFont(gFonts['small'])
    for _, ft in ipairs(self.floatingTexts) do
        if ft.dimension == curDim then
            love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], ft.opacity)
            love.graphics.printf(ft.text, ft.x - 60, ft.y, 120, 'center')
        end
    end

    -- Dimensional Warp Screen Flash / Shockwave
    if self.shiftTransitionTimer > 0 then
        local alpha = (self.shiftTransitionTimer / self.shiftTransitionMax) * 0.45
        local col = (curDim == 'nether') and {0.8, 0.2, 1.0} or {0.2, 0.8, 1.0}
        love.graphics.setColor(col[1], col[2], col[3], alpha)
        love.graphics.rectangle('fill', 0, 0, push:getWidth(), push:getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- HUD Overlay (Top Bar & Dimension Indicator)
    self:renderHUD()
end

function PlayState:renderHUD()
    local curDim = self.hero.dimension

    -- Top Bar Background
    love.graphics.setColor(0.04, 0.06, 0.1, 0.88)
    love.graphics.rectangle('fill', 0, 0, push:getWidth(), 24)
    love.graphics.setColor(0.2, 0.25, 0.35, 1)
    love.graphics.line(0, 24, push:getWidth(), 24)

    -- Hero HP
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][1], 6, 4)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0.2, 0.9, 0.3, 1)
    love.graphics.print(self.hero.health .. '/' .. self.hero.maxHealth, 24, 4)

    -- Coins (Gold)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][2], 85, 4)
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.print(tostring(self.hero.gold), 105, 4)

    -- Ores (Stone)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][3], 145, 4)
    love.graphics.setColor(0.85, 0.85, 0.9, 1)
    love.graphics.print(tostring(self.hero.stone), 165, 4)

    -- Gems (Void Essence)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][4], 205, 4)
    love.graphics.setColor(0.9, 0.4, 1.0, 1)
    love.graphics.print(tostring(self.hero.voidEssence), 225, 4)

    -- Current Dimension Badge
    love.graphics.setFont(gFonts['small'])
    if curDim == 'overworld' then
        love.graphics.setColor(0.2, 0.6, 1.0, 0.9)
        love.graphics.rectangle('fill', 270, 4, 90, 16, 3, 3)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("[SURFACE REALM]", 270, 7, 90, 'center')
    else
        love.graphics.setColor(0.8, 0.2, 0.9, 0.9)
        love.graphics.rectangle('fill', 270, 4, 90, 16, 3, 3)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("[NETHER REALM]", 270, 7, 90, 'center')
    end

    -- Nether Anchor / Underworld AI Status
    local enemyAnchor = self.grid:getAnchor('nether', 'enemy')
    if enemyAnchor then
        love.graphics.setColor(0.9, 0.3, 0.8, 1)
        love.graphics.print('Underworld Anchor: ' .. enemyAnchor.health .. 'HP (Shielding Core!)', 370, 6)
    else
        love.graphics.setColor(0.3, 0.9, 0.4, 1)
        love.graphics.print('Underworld Anchor: DESTROYED (Core Vulnerable!)', 370, 6)
    end

    -- Next Wave Timer
    local waveTimeLeft = math.max(0, math.ceil(self.playerCore.spawnInterval - self.playerCore.spawnTimer))
    love.graphics.setColor(0.9, 0.9, 0.5, 1)
    love.graphics.print('Wave: ' .. waveTimeLeft .. 's', 575, 6)

    -- Bottom Controls Hint Bar
    love.graphics.setColor(0.04, 0.06, 0.1, 0.8)
    love.graphics.rectangle('fill', 0, push:getHeight() - 16, push:getWidth(), 16)
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.setFont(gFonts['small'])
    local shiftPrompt = (self.hero.shiftCooldown <= 0) and 'Q/Shift: [SHIFT REALM]' or 'Q: Cooldown'
    love.graphics.print('WASD: Move | J: Attack | Space: Mine/Build | ' .. shiftPrompt .. ' | 1:Wall 2:Turret 3:Anchor 4:Healer | Esc: Pause', 6, push:getHeight() - 13)
    love.graphics.setColor(1, 1, 1, 1)
end

return PlayState