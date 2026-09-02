local BaseState = require 'src.states.BaseState'
local Grid = require 'src.world.Grid'
local Tile = require 'src.world.Tile'
local Hero = require 'src.entities.Hero'
local EnemyHero = require 'src.entities.EnemyHero'
local Boss = require 'src.entities.Boss'
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
    self.enemyHero = EnemyHero(TILE_SIZE * 17, TILE_SIZE * 5)
    self.boss = Boss(TILE_SIZE * 10, TILE_SIZE * 8)
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

    -- Screen Shake
    self.shakeIntensity = 0
    self.shakeDuration = 0
    self.shakeTimer = 0

    -- Dynamic Dimensional Storms
    self.stormTimer = 0
    self.stormInterval = 60.0 -- Storm occurs every 60s
    self.stormDuration = 10.0
    self.isStormActive = false

    -- Tech Upgrade Shop Modal State
    self.shopOpen = false
    self.shopSelection = 1
    self.shopItems = {
        { id = 'blades', name = 'Sharpened Blades (+12 DMG)', costGold = 40, costStone = 30, costEssence = 0 },
        { id = 'boots', name = 'Swift Greaves (+22 Speed)', costGold = 35, costStone = 20, costEssence = 0 },
        { id = 'armor', name = 'Reinforced Armor (+40 Max HP)', costGold = 50, costStone = 40, costEssence = 10 },
        { id = 'turrets', name = 'Overclock Core (Faster Turrets)', costGold = 60, costStone = 50, costEssence = 25 }
    }

    self.gameOver = false
    self.gameTimer = 0
end

function PlayState:enter(params)
    params = params or {}
    if not params.resume then
        self:init()
    end
end

function PlayState:triggerScreenShake(intensity, duration)
    self.shakeIntensity = intensity or 5
    self.shakeDuration = duration or 0.2
    self.shakeTimer = self.shakeDuration
end

function PlayState:triggerDimensionShift(targetDim)
    self.shiftTransitionTimer = self.shiftTransitionMax
    self.currentRenderDim = targetDim

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

function PlayState:spawnSiegeJuggernaut(owner)
    local minion = Minion(TILE_SIZE * 3, TILE_SIZE * 5, owner or 'player', 'overworld')
    minion.maxHealth = 220
    minion.health = minion.maxHealth
    minion.damage = 30
    minion.size = 20
    table.insert(self.minions, minion)
    self:addFloatingText(minion.x, minion.y - 12, "SIEGE JUGGERNAUT SUMMONED!", {1.0, 0.8, 0.2}, 'overworld')
end

function PlayState:update(dt)
    if self.gameOver then return end
    self.gameTimer = self.gameTimer + dt

    -- Update Visual Effects even when shop is open (so purchase feedback shows)
    for i = #self.floatingTexts, 1, -1 do
        local ft = self.floatingTexts[i]
        ft.life = ft.life - dt
        ft.y = ft.y + ft.vy * dt
        ft.opacity = ft.life / 0.8
        if ft.life <= 0 then
            table.remove(self.floatingTexts, i)
        end
    end

    -- Tech Shop input handling if open
    if self.shopOpen then
        return
    end

    -- Screen Shake Timer
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
    end

    if self.shiftTransitionTimer > 0 then
        self.shiftTransitionTimer = self.shiftTransitionTimer - dt
    end

    -- Dimensional Storm Tick
    self.stormTimer = self.stormTimer + dt
    if self.stormTimer >= self.stormInterval then
        if not self.isStormActive then
            self.isStormActive = true
            gSounds['storm']:play()
            self:triggerScreenShake(6, 0.8)
            self:addFloatingText(push:getWidth() / 2, 40, "WARNING: DIMENSIONAL STORM UNLEASHED!", {1, 0.2, 0.8}, 'nether')
        end

        if self.stormTimer >= self.stormInterval + self.stormDuration then
            self.stormTimer = 0
            self.isStormActive = false
        end

        -- Damage units caught in Nether without shelter during storm
        if self.hero.dimension == 'nether' and math.random() < 0.2 then
            self.hero:takeDamage(4)
            self:addSparks(self.hero.x + 9, self.hero.y + 9, {0.9, 0.2, 1.0}, 'nether')
        end
    end

    -- Update Entities
    self.hero:update(dt, self.grid, self)
    self.enemyHero:update(dt, self.grid, self)
    self.boss:update(dt, self)
    self.grid:update(dt, self)
    self.playerCore:update(dt, self)
    self.enemyCore:update(dt, self)
    self.enemyAI:update(dt)

    -- Check Boss death for Juggernaut spawn
    if self.boss and not self.boss:isAlive() and not self.bossRewardGranted then
        self.bossRewardGranted = true
        self:spawnSiegeJuggernaut('player')
        self:addFloatingText(push:getWidth() / 2, 60, "VOID GOLEM SLAIN! TEAM GAINED VOID FURY & JUGGERNAUT!", {1, 0.85, 0.2}, 'overworld')
        self:addFloatingText(push:getWidth() / 2, 60, "VOID GOLEM SLAIN! TEAM GAINED VOID FURY & JUGGERNAUT!", {1, 0.85, 0.2}, 'nether')
    end

    -- Update Minions
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

function PlayState:buyShopItem(index)
    local item = self.shopItems[index]
    if not item then return end

    if self.hero.gold >= item.costGold and self.hero.stone >= item.costStone and self.hero.voidEssence >= item.costEssence then
        self.hero.gold = self.hero.gold - item.costGold
        self.hero.stone = self.hero.stone - item.costStone
        self.hero.voidEssence = self.hero.voidEssence - item.costEssence
        self.hero:applyUpgrade(item.id)
        gSounds['upgrade']:stop()
        gSounds['upgrade']:play()
        self:addFloatingText(self.hero.x, self.hero.y - 12, "Purchased: " .. item.name, {0.3, 1, 0.4}, self.hero.dimension)
    else
        self:addFloatingText(self.hero.x, self.hero.y - 12, "Insufficient Resources!", {1, 0.3, 0.3}, self.hero.dimension)
    end
end

function PlayState:keypressed(key)
    if self.shopOpen then
        if key == 'b' or key == 'escape' then
            self.shopOpen = false
        elseif key == 'up' or key == 'w' then
            self.shopSelection = math.max(1, self.shopSelection - 1)
        elseif key == 'down' or key == 's' then
            self.shopSelection = math.min(#self.shopItems, self.shopSelection + 1)
        elseif key == 'return' or key == 'space' then
            self:buyShopItem(self.shopSelection)
        end
        return
    end

    if key == 'escape' or key == 'p' then
        gStateMachine:change('pause', { previousState = self })
    elseif key == 'b' then
        self.shopOpen = true
    elseif key == 'space' or key == 'k' then
        self.hero:mineOrBuild(self.grid, self)
    elseif key == 'j' or key == 'lctrl' then
        self.hero:attack(self)
    elseif key == 'e' then
        self.hero:castDash(self.grid, self)
    elseif key == 'r' then
        self.hero:castUltimate(self.grid, self)
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

    love.graphics.push()

    -- Screen Shake Translation
    if self.shakeTimer > 0 then
        local ox = (math.random() * 2 - 1) * self.shakeIntensity
        local oy = (math.random() * 2 - 1) * self.shakeIntensity
        love.graphics.translate(ox, oy)
    end

    -- Render Active Dimension Tile Map
    self.grid:render(curDim)

    -- Void Realm Atmospheric Overlay & Storm Lighting
    if curDim == 'nether' then
        local stormBonus = (self.isStormActive) and (math.sin(love.timer.getTime() * 20) * 0.15 + 0.15) or 0
        love.graphics.setColor(0.25 + stormBonus, 0.05, 0.4 + stormBonus, 0.22 + stormBonus)
        love.graphics.rectangle('fill', 0, 0, push:getWidth(), push:getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Render Target Indicator for Hero
    local tgx, tgy = self.hero:getTargetGridPosition(self.grid)
    local twx, twy = self.grid:gridToWorld(tgx, tgy)
    love.graphics.setColor(1, 1, 1, 0.4 + math.sin(love.timer.getTime() * 8) * 0.2)
    love.graphics.rectangle('line', twx, twy, TILE_SIZE, TILE_SIZE)
    love.graphics.setColor(1, 1, 1, 1)

    -- Render Cores
    if curDim == 'overworld' then
        self.playerCore:render(self)
        self.enemyCore:render(self)
    else
        love.graphics.setColor(0.3, 0.7, 1.0, 0.25)
        love.graphics.rectangle('line', self.playerCore.x, self.playerCore.y, 32, 32)
        love.graphics.setColor(1.0, 0.3, 0.3, 0.25)
        love.graphics.rectangle('line', self.enemyCore.x, self.enemyCore.y, 32, 32)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Render Minions
    for _, minion in ipairs(self.minions) do
        if minion.dimension == curDim then
            minion:render()
        end
    end

    -- Render Boss (in Nether)
    if curDim == 'nether' and self.boss then
        self.boss:render()
    end

    -- Render Enemy Hero
    if self.enemyHero.dimension == curDim then
        self.enemyHero:render()
    end

    -- Render Hero
    self.hero:render()

    -- Render Lasers
    for _, lz in ipairs(self.lasers) do
        if lz.dimension == curDim then
            love.graphics.setColor(lz.color[1], lz.color[2], lz.color[3], lz.life / 0.12)
            love.graphics.setLineWidth(3)
            love.graphics.line(lz.x1, lz.y1, lz.x2, lz.y2)
            love.graphics.setLineWidth(1)
        end
    end

    -- Render Slashes
    for _, sl in ipairs(self.slashes) do
        if sl.dimension == curDim then
            love.graphics.setColor(1, 1, 1, sl.life / 0.15)
            love.graphics.circle('line', sl.x, sl.y, sl.radius)
        end
    end

    -- Render Sparks
    for _, sp in ipairs(self.sparks) do
        if sp.dimension == curDim then
            love.graphics.setColor(sp.color[1], sp.color[2], sp.color[3], sp.life / 0.25)
            love.graphics.rectangle('fill', sp.x, sp.y, 2, 2)
        end
    end

    -- Render Floating Texts
    love.graphics.setFont(gFonts['small'])
    for _, ft in ipairs(self.floatingTexts) do
        if ft.dimension == curDim then
            love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], ft.opacity)
            love.graphics.printf(ft.text, ft.x - 60, ft.y, 120, 'center')
        end
    end

    -- Dimensional Warp Flash
    if self.shiftTransitionTimer > 0 then
        local alpha = (self.shiftTransitionTimer / self.shiftTransitionMax) * 0.45
        local col = (curDim == 'nether') and {0.8, 0.2, 1.0} or {0.2, 0.8, 1.0}
        love.graphics.setColor(col[1], col[2], col[3], alpha)
        love.graphics.rectangle('fill', 0, 0, push:getWidth(), push:getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.pop()

    -- HUD Overlay & Minimap
    self:renderHUD()
    self:renderMinimap()

    -- Tech Shop Modal
    if self.shopOpen then
        self:renderShopModal()
    end
end

function PlayState:renderMinimap()
    local mapW = 90
    local mapH = 48
    local mapX = push:getWidth() - mapW - 6
    local mapY = 28

    -- Minimap Frame
    love.graphics.setColor(0.05, 0.07, 0.12, 0.9)
    love.graphics.rectangle('fill', mapX, mapY, mapW, mapH, 4, 4)
    love.graphics.setColor(0.3, 0.4, 0.6, 0.8)
    love.graphics.rectangle('line', mapX, mapY, mapW, mapH, 4, 4)

    -- Divide line between Surface / Nether
    love.graphics.setColor(0.4, 0.5, 0.7, 0.4)
    love.graphics.line(mapX + mapW / 2, mapY, mapX + mapW / 2, mapY + mapH)

    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.4, 0.8, 1.0, 0.6)
    love.graphics.print("SURF", mapX + 3, mapY + 2)
    love.graphics.setColor(0.9, 0.4, 1.0, 0.6)
    love.graphics.print("NETH", mapX + mapW / 2 + 3, mapY + 2)

    -- Draw Cores
    love.graphics.setColor(0.2, 0.6, 1.0, 1)
    love.graphics.rectangle('fill', mapX + 6, mapY + mapH / 2 - 2, 4, 4)
    love.graphics.setColor(1.0, 0.2, 0.2, 1)
    love.graphics.rectangle('fill', mapX + mapW / 2 - 8, mapY + mapH / 2 - 2, 4, 4)

    -- Draw Boss (in Nether side)
    if self.boss and self.boss:isAlive() then
        love.graphics.setColor(0.9, 0.2, 1.0, 1)
        love.graphics.rectangle('fill', mapX + mapW / 2 + mapW / 4, mapY + mapH - 8, 4, 4)
    end

    -- Draw Hero Blip
    local hxNorm = (self.hero.x / push:getWidth()) * (mapW / 2)
    local hyNorm = (self.hero.y / push:getHeight()) * mapH
    local hBaseX = (self.hero.dimension == 'overworld') and mapX or (mapX + mapW / 2)
    love.graphics.setColor(0.2, 1.0, 0.4, 1)
    love.graphics.circle('fill', hBaseX + hxNorm, mapY + hyNorm, 3)

    -- Draw Enemy Hero Blip
    if self.enemyHero and self.enemyHero:isAlive() then
        local ehNorm = (self.enemyHero.x / push:getWidth()) * (mapW / 2)
        local ehyNorm = (self.enemyHero.y / push:getHeight()) * mapH
        local ehBaseX = (self.enemyHero.dimension == 'overworld') and mapX or (mapX + mapW / 2)
        love.graphics.setColor(1.0, 0.2, 0.2, 1)
        love.graphics.circle('fill', ehBaseX + ehNorm, mapY + ehyNorm, 2.5)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:renderShopModal()
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle('fill', 0, 0, push:getWidth(), push:getHeight())

    local sw = 420
    local sh = 230
    local sx = (push:getWidth() - sw) / 2
    local sy = (push:getHeight() - sh) / 2

    love.graphics.setColor(0.08, 0.1, 0.16, 0.95)
    love.graphics.rectangle('fill', sx, sy, sw, sh, 6, 6)
    love.graphics.setColor(0.3, 0.7, 1.0, 0.9)
    love.graphics.rectangle('line', sx, sy, sw, sh, 6, 6)

    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.printf("NEXUS TECH UPGRADE SHOP", sx, sy + 12, sw, 'center')

    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.7, 0.8, 0.9, 1)
    love.graphics.printf("Use UP / DOWN / ENTER to Buy | Press 'B' or ESC to Close", sx, sy + 30, sw, 'center')

    for i, item in ipairs(self.shopItems) do
        local iy = sy + 55 + (i - 1) * 38
        if self.shopSelection == i then
            love.graphics.setColor(0.2, 0.5, 0.9, 0.35)
            love.graphics.rectangle('fill', sx + 12, iy - 2, sw - 24, 32, 4, 4)
            love.graphics.setColor(0.4, 0.8, 1.0, 1)
            love.graphics.rectangle('line', sx + 12, iy - 2, sw - 24, 32, 4, 4)
        end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(item.name, sx + 22, iy + 2)

        local costStr = "Cost: " .. item.costGold .. " Coins, " .. item.costStone .. " Ores"
        if item.costEssence > 0 then
            costStr = costStr .. ", " .. item.costEssence .. " Gems"
        end
        love.graphics.setColor(0.9, 0.8, 0.3, 1)
        love.graphics.print(costStr, sx + 22, iy + 16)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:renderHUD()
    local curDim = self.hero.dimension

    -- Top Bar
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

    -- Coins
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][2], 85, 4)
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.print(tostring(self.hero.gold), 105, 4)

    -- Ores
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][3], 145, 4)
    love.graphics.setColor(0.85, 0.85, 0.9, 1)
    love.graphics.print(tostring(self.hero.stone), 165, 4)

    -- Gems
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['ui'], gFrames['ui'][4], 205, 4)
    love.graphics.setColor(0.9, 0.4, 1.0, 1)
    love.graphics.print(tostring(self.hero.voidEssence), 225, 4)

    -- Current Dimension Badge
    love.graphics.setFont(gFonts['small'])
    if curDim == 'overworld' then
        love.graphics.setColor(0.2, 0.6, 1.0, 0.9)
        love.graphics.rectangle('fill', 265, 4, 85, 16, 3, 3)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("[SURFACE]", 265, 7, 85, 'center')
    else
        love.graphics.setColor(0.8, 0.2, 0.9, 0.9)
        love.graphics.rectangle('fill', 265, 4, 85, 16, 3, 3)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("[NETHER]", 265, 7, 85, 'center')
    end

    -- Abilities Cooldown Badges
    local dashReady = (self.hero.dashCooldown <= 0)
    love.graphics.setColor(dashReady and {0.2, 0.8, 1} or {0.4, 0.4, 0.4})
    love.graphics.print("[E] Dash " .. (dashReady and "READY" or string.format("%.1fs", self.hero.dashCooldown)), 355, 6)

    local ultReady = (self.hero.ultCooldown <= 0)
    love.graphics.setColor(ultReady and {1.0, 0.85, 0.2} or {0.4, 0.4, 0.4})
    love.graphics.print("[R] Ult " .. (ultReady and "READY" or string.format("%.1fs", self.hero.ultCooldown)), 430, 6)

    -- Tech Shop Prompt
    love.graphics.setColor(0.3, 1.0, 0.6, 1)
    love.graphics.print("[B] Shop", 500, 6)

    -- Bottom Controls Hint Bar
    love.graphics.setColor(0.04, 0.06, 0.1, 0.8)
    love.graphics.rectangle('fill', 0, push:getHeight() - 16, push:getWidth(), 16)
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.setFont(gFonts['small'])
    local shiftPrompt = (self.hero.shiftCooldown <= 0) and 'Q/Shift: [SHIFT REALM]' or 'Q: Cooldown'
    love.graphics.print('WASD: Move | J: Attack | E: Dash | R: Ult | Space: Mine/Build | ' .. shiftPrompt .. ' | 1-4: Build | B: Shop', 6, push:getHeight() - 13)
    love.graphics.setColor(1, 1, 1, 1)
end

return PlayState