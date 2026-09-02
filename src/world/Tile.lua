Tile = Class{}

Tile.EMPTY = 1
Tile.WALL = 2
Tile.GOLD = 3
Tile.CRYSTAL = 4
Tile.TURRET_PLAYER = 5
Tile.TURRET_ENEMY = 6
Tile.CORE_PLAYER = 7
Tile.CORE_ENEMY = 8

function Tile:init(gridX, gridY, tileType)
    self.gridX = gridX
    self.gridY = gridY
    self.type = tileType or Tile.EMPTY
    self.maxHealth = self:getDefaultHealth()
    self.health = self.maxHealth
    self.shootTimer = 0
    self.shootInterval = 1.2
    self.range = 100
end

function Tile:getDefaultHealth()
    if self.type == Tile.WALL then
        return 100
    elseif self.type == Tile.GOLD then
        return 60
    elseif self.type == Tile.CRYSTAL then
        return 80
    elseif self.type == Tile.TURRET_PLAYER or self.type == Tile.TURRET_ENEMY then
        return 120
    else
        return 1
    end
end

function Tile:isSolid()
    return self.type == Tile.WALL or 
           self.type == Tile.GOLD or 
           self.type == Tile.CRYSTAL or 
           self.type == Tile.TURRET_PLAYER or 
           self.type == Tile.TURRET_ENEMY
end

function Tile:isResource()
    return self.type == Tile.GOLD or self.type == Tile.CRYSTAL
end

function Tile:isTurret()
    return self.type == Tile.TURRET_PLAYER or self.type == Tile.TURRET_ENEMY
end

function Tile:setType(tileType)
    self.type = tileType
    self.maxHealth = self:getDefaultHealth()
    self.health = self.maxHealth
    self.shootTimer = 0
end

function Tile:takeDamage(amount)
    self.health = math.clamp(self.health - amount, 0, self.maxHealth)
    return self.health <= 0
end

function Tile:update(dt, playState)
    if not self:isTurret() then return end

    self.shootTimer = self.shootTimer + dt
    if self.shootTimer >= self.shootInterval then
        self.shootTimer = 0
        self:fireTurret(playState)
    end
end

function Tile:fireTurret(playState)
    local cx = (self.gridX - 0.5) * 32
    local cy = (self.gridY - 0.5) * 32
    local isPlayerTurret = (self.type == Tile.TURRET_PLAYER)

    local target = nil
    local closestDist = self.range

    -- Check minions
    for _, minion in ipairs(playState.minions) do
        if minion:isAlive() and ((isPlayerTurret and minion.owner == 'enemy') or (not isPlayerTurret and minion.owner == 'player')) then
            local d = Distance(cx, cy, minion.x + minion.size / 2, minion.y + minion.size / 2)
            if d < closestDist then
                closestDist = d
                target = minion
            end
        end
    end

    -- If enemy turret and no minion, target hero
    if not target and not isPlayerTurret and playState.hero:isAlive() then
        local d = Distance(cx, cy, playState.hero.x + playState.hero.width / 2, playState.hero.y + playState.hero.height / 2)
        if d < closestDist then
            target = playState.hero
        end
    end

    if target then
        gSounds['shoot']:stop()
        gSounds['shoot']:play()
        
        local tx = (target.x + (target.width or target.size or 16) / 2)
        local ty = (target.y + (target.height or target.size or 16) / 2)
        
        playState:addLaser(cx, cy, tx, ty, isPlayerTurret and {0.2, 0.6, 1} or {1, 0.2, 0.2})
        target:takeDamage(15)
    end
end

function Tile:render(pixelX, pixelY, tileSize)
    -- Base Grass Floor
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['tileset'], gFrames['tiles'][Tile.EMPTY], pixelX, pixelY)

    -- Specific Tile Structure
    if self.type ~= Tile.EMPTY then
        love.graphics.draw(gTextures['tileset'], gFrames['tiles'][self.type], pixelX, pixelY)

        -- Health bar for structures if damaged
        if self.health < self.maxHealth and self.maxHealth > 1 then
            local hpPercent = self.health / self.maxHealth
            love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
            love.graphics.rectangle('fill', pixelX + 2, pixelY + 2, tileSize - 4, 3)
            love.graphics.setColor(0.2, 0.9, 0.2, 0.9)
            love.graphics.rectangle('fill', pixelX + 2, pixelY + 2, (tileSize - 4) * hpPercent, 3)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return Tile