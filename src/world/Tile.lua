Tile = Class{}

-- Overworld Tiles (1 - 8)
Tile.EMPTY = 1
Tile.WALL = 2
Tile.GOLD = 3
Tile.CRYSTAL = 4
Tile.TURRET_PLAYER = 5
Tile.TURRET_ENEMY = 6
Tile.CORE_PLAYER = 7
Tile.CORE_ENEMY = 8

-- Nether / Void Realm Tiles (9 - 14)
Tile.VOID_FLOOR = 9
Tile.VOID_WALL = 10
Tile.VOID_CRYSTAL = 11
Tile.RIFT_PORTAL = 12
Tile.NETHER_ANCHOR_PLAYER = 13
Tile.NETHER_ANCHOR_ENEMY = 14

-- Special Neutral / Sanctuary Structure (15)
Tile.HEALING_CHAMBER = 15

function Tile:init(gridX, gridY, tileType, dimension)
    self.gridX = gridX
    self.gridY = gridY
    self.dimension = dimension or 'overworld'
    self.type = tileType or (self.dimension == 'nether' and Tile.VOID_FLOOR or Tile.EMPTY)
    self.maxHealth = self:getDefaultHealth()
    self.health = self.maxHealth
    self.shootTimer = 0
    self.shootInterval = 1.2
    self.range = 100
    self.healTimer = 0
    self.healInterval = 0.5
end

function Tile:getDefaultHealth()
    if self.type == Tile.WALL or self.type == Tile.VOID_WALL then
        return 100
    elseif self.type == Tile.GOLD then
        return 60
    elseif self.type == Tile.CRYSTAL or self.type == Tile.VOID_CRYSTAL then
        return 80
    elseif self.type == Tile.TURRET_PLAYER or self.type == Tile.TURRET_ENEMY then
        return 120
    elseif self.type == Tile.NETHER_ANCHOR_PLAYER or self.type == Tile.NETHER_ANCHOR_ENEMY then
        return 250
    elseif self.type == Tile.HEALING_CHAMBER then
        return 300
    elseif self.type == Tile.RIFT_PORTAL then
        return 99999
    else
        return 1
    end
end

function Tile:isSolid()
    return self.type == Tile.WALL or 
           self.type == Tile.GOLD or 
           self.type == Tile.CRYSTAL or 
           self.type == Tile.TURRET_PLAYER or 
           self.type == Tile.TURRET_ENEMY or
           self.type == Tile.VOID_WALL or
           self.type == Tile.VOID_CRYSTAL or
           self.type == Tile.NETHER_ANCHOR_PLAYER or
           self.type == Tile.NETHER_ANCHOR_ENEMY or
           self.type == Tile.HEALING_CHAMBER
end

function Tile:isResource()
    return self.type == Tile.GOLD or self.type == Tile.CRYSTAL or self.type == Tile.VOID_CRYSTAL
end

function Tile:isTurret()
    return self.type == Tile.TURRET_PLAYER or self.type == Tile.TURRET_ENEMY
end

function Tile:isAnchor()
    return self.type == Tile.NETHER_ANCHOR_PLAYER or self.type == Tile.NETHER_ANCHOR_ENEMY
end

function Tile:isHealingChamber()
    return self.type == Tile.HEALING_CHAMBER
end

function Tile:setType(tileType)
    self.type = tileType
    self.maxHealth = self:getDefaultHealth()
    self.health = self.maxHealth
    self.shootTimer = 0
    self.healTimer = 0
end

function Tile:takeDamage(amount)
    if self.type == Tile.RIFT_PORTAL then return false end
    self.health = math.clamp(self.health - amount, 0, self.maxHealth)
    return self.health <= 0
end

function Tile:update(dt, playState)
    if self:isTurret() then
        self.shootTimer = self.shootTimer + dt
        if self.shootTimer >= self.shootInterval then
            self.shootTimer = 0
            self:fireTurret(playState)
        end
    elseif self:isAnchor() then
        self.shootTimer = self.shootTimer + dt
        if self.shootTimer >= self.shootInterval then
            self.shootTimer = 0
            self:pulseAnchor(playState)
        end
    elseif self:isHealingChamber() then
        self.healTimer = self.healTimer + dt
        if self.healTimer >= self.healInterval then
            self.healTimer = 0
            self:pulseHealing(playState)
        end
    end
end

function Tile:pulseHealing(playState)
    local cx = (self.gridX - 0.5) * 32
    local cy = (self.gridY - 0.5) * 32

    -- Heal hero if nearby in the same dimension
    if playState.hero:isAlive() and playState.hero.dimension == self.dimension then
        local d = Distance(cx, cy, playState.hero.x + playState.hero.width / 2, playState.hero.y + playState.hero.height / 2)
        if d < 65 and playState.hero.health < playState.hero.maxHealth then
            local healAmt = math.min(10, playState.hero.maxHealth - playState.hero.health)
            playState.hero.health = playState.hero.health + healAmt
            playState:addFloatingText(playState.hero.x, playState.hero.y - 10, "+" .. healAmt .. " HP", {0.2, 1.0, 0.4}, self.dimension)
            playState:addSparks(playState.hero.x + 8, playState.hero.y + 8, {0.2, 1.0, 0.5}, self.dimension)
        end
    end

    -- Also repair nearby allied player minions
    for _, minion in ipairs(playState.minions) do
        if minion:isAlive() and minion.dimension == self.dimension and minion.owner == 'player' and minion.health < minion.maxHealth then
            local d = Distance(cx, cy, minion.x + minion.size / 2, minion.y + minion.size / 2)
            if d < 55 then
                minion.health = math.min(minion.maxHealth, minion.health + 8)
                playState:addSparks(minion.x + 8, minion.y + 8, {0.3, 1.0, 0.6}, self.dimension)
            end
        end
    end
end

function Tile:fireTurret(playState)
    local cx = (self.gridX - 0.5) * 32
    local cy = (self.gridY - 0.5) * 32
    local isPlayerTurret = (self.type == Tile.TURRET_PLAYER)

    local target = nil
    local closestDist = self.range

    -- Check minions in current dimension
    for _, minion in ipairs(playState.minions) do
        if minion:isAlive() and minion.dimension == self.dimension and 
           ((isPlayerTurret and minion.owner == 'enemy') or (not isPlayerTurret and minion.owner == 'player')) then
            local d = Distance(cx, cy, minion.x + minion.size / 2, minion.y + minion.size / 2)
            if d < closestDist then
                closestDist = d
                target = minion
            end
        end
    end

    -- If enemy turret and no minion, target hero if in same dimension
    if not target and not isPlayerTurret and playState.hero:isAlive() and playState.hero.dimension == self.dimension then
        local d = Distance(cx, cy, playState.hero.x + playState.hero.width / 2, playState.hero.y + playState.hero.height / 2)
        if d < closestDist then
            target = playState.hero
        end
    end

    if target then
        -- Play sound only if player is in the same realm
        if playState.hero.dimension == self.dimension then
            gSounds['shoot']:stop()
            gSounds['shoot']:play()
        end
        
        local tx = (target.x + (target.width or target.size or 16) / 2)
        local ty = (target.y + (target.height or target.size or 16) / 2)
        
        playState:addLaser(cx, cy, tx, ty, isPlayerTurret and {0.2, 0.6, 1} or {1, 0.2, 0.2}, self.dimension)
        target:takeDamage(15)
    end
end

function Tile:pulseAnchor(playState)
    local cx = (self.gridX - 0.5) * 32
    local cy = (self.gridY - 0.5) * 32
    local isPlayerAnchor = (self.type == Tile.NETHER_ANCHOR_PLAYER)

    -- Anchor periodically attacks enemy units in Nether or pulses energy
    for _, minion in ipairs(playState.minions) do
        if minion:isAlive() and minion.dimension == 'nether' and
           ((isPlayerAnchor and minion.owner == 'enemy') or (not isPlayerAnchor and minion.owner == 'player')) then
            local d = Distance(cx, cy, minion.x + minion.size / 2, minion.y + minion.size / 2)
            if d < 120 then
                playState:addLaser(cx, cy, minion.x + 8, minion.y + 8, isPlayerAnchor and {0.4, 0.8, 1} or {1, 0.3, 0.7}, 'nether')
                minion:takeDamage(20)
                playState:addSparks(minion.x + 8, minion.y + 8, {0.9, 0.3, 1}, 'nether')
            end
        end
    end

    if not isPlayerAnchor and playState.hero:isAlive() and playState.hero.dimension == 'nether' then
        local d = Distance(cx, cy, playState.hero.x + playState.hero.width / 2, playState.hero.y + playState.hero.height / 2)
        if d < 100 then
            playState:addLaser(cx, cy, playState.hero.x + 12, playState.hero.y + 12, {1, 0.2, 0.6}, 'nether')
            playState.hero:takeDamage(12)
            playState:addSparks(playState.hero.x + 12, playState.hero.y + 12, {1, 0.2, 0.8}, 'nether')
        end
    end
end

function Tile:render(pixelX, pixelY, tileSize)
    -- Base Floor Quad depending on dimension
    love.graphics.setColor(1, 1, 1, 1)
    local baseQuadIndex = (self.dimension == 'nether') and Tile.VOID_FLOOR or Tile.EMPTY
    love.graphics.draw(gTextures['tileset'], gFrames['tiles'][baseQuadIndex], pixelX, pixelY)

    -- Specific Tile Structure
    if self.type ~= Tile.EMPTY and self.type ~= Tile.VOID_FLOOR then
        local quad = gFrames['tiles'][self.type]
        if quad then
            love.graphics.draw(gTextures['tileset'], quad, pixelX, pixelY)
        end

        -- Healing Chamber Green Aura Pulse
        if self:isHealingChamber() then
            local pulse = (math.sin(love.timer.getTime() * 5) + 1) * 0.5
            love.graphics.setColor(0.2, 1.0, 0.5, 0.2 + pulse * 0.25)
            love.graphics.circle('line', pixelX + tileSize / 2, pixelY + tileSize / 2, 16 + pulse * 4)
            love.graphics.setColor(1, 1, 1, 1)
        end

        -- Health bar for structures if damaged
        if self.health < self.maxHealth and self.maxHealth > 1 and self.type ~= Tile.RIFT_PORTAL then
            local hpPercent = self.health / self.maxHealth
            love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
            love.graphics.rectangle('fill', pixelX + 2, pixelY + 2, tileSize - 4, 3)
            if self:isAnchor() then
                love.graphics.setColor(0.8, 0.3, 1.0, 0.9)
            elseif self:isHealingChamber() then
                love.graphics.setColor(0.2, 1.0, 0.4, 0.9)
            else
                love.graphics.setColor(0.2, 0.9, 0.2, 0.9)
            end
            love.graphics.rectangle('fill', pixelX + 2, pixelY + 2, (tileSize - 4) * hpPercent, 3)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return Tile