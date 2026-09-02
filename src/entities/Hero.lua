local Tile = require 'src.world.Tile'

Hero = Class{}

function Hero:init(x, y)
    self.x = x or 64
    self.y = y or 160
    self.width = 18
    self.height = 18
    self.speed = 120

    self.maxHealth = 100
    self.health = self.maxHealth
    self.gold = 50
    self.stone = 30

    self.direction = 'right'
    self.isMoving = false
    self.isAttacking = false
    self.attackCooldown = 0
    self.attackCooldownMax = 0.25

    self.mineCooldown = 0
    self.mineCooldownMax = 0.25

    self.invulnerable = false
    self.invulnTimer = 0

    self.buildSelection = 'wall' -- 'wall' or 'turret'

    -- Anim8 setup
    local g = anim8.newGrid(24, 24, gTextures['hero']:getWidth(), gTextures['hero']:getHeight())
    self.animations = {
        ['idle'] = anim8.newAnimation(g(1, 1), 1),
        ['walk'] = anim8.newAnimation(g(2, 1, 3, 1), 0.15),
        ['attack'] = anim8.newAnimation(g(4, 1), 0.2)
    }
    self.currentAnimation = self.animations['idle']
end

function Hero:isAlive()
    return self.health > 0
end

function Hero:takeDamage(amount)
    if self.invulnerable or not self:isAlive() then return end

    self.health = math.clamp(self.health - amount, 0, self.maxHealth)
    self.invulnerable = true
    self.invulnTimer = 0.5

    gSounds['hit']:stop()
    gSounds['hit']:play()
end

function Hero:getGridPosition(grid)
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2
    return grid:worldToGrid(centerX, centerY)
end

function Hero:getTargetGridPosition(grid)
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2

    if self.direction == 'left' then
        centerX = centerX - 24
    elseif self.direction == 'right' then
        centerX = centerX + 24
    elseif self.direction == 'up' then
        centerY = centerY - 24
    elseif self.direction == 'down' then
        centerY = centerY + 24
    end

    return grid:worldToGrid(centerX, centerY)
end

function Hero:update(dt, grid, playState)
    if not self:isAlive() then return end

    -- Cooldowns
    if self.attackCooldown > 0 then
        self.attackCooldown = self.attackCooldown - dt
        if self.attackCooldown <= 0 then
            self.isAttacking = false
        end
    end

    if self.mineCooldown > 0 then
        self.mineCooldown = self.mineCooldown - dt
    end

    if self.invulnerable then
        self.invulnTimer = self.invulnTimer - dt
        if self.invulnTimer <= 0 then
            self.invulnerable = false
        end
    end

    -- Movement
    local dx = 0
    local dy = 0

    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        dy = dy - 1
        self.direction = 'up'
    end
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        dy = dy + 1
        self.direction = 'down'
    end
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        dx = dx - 1
        self.direction = 'left'
    end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        dx = dx + 1
        self.direction = 'right'
    end

    self.isMoving = (dx ~= 0 or dy ~= 0)

    if self.isMoving then
        -- Normalize
        local len = math.sqrt(dx * dx + dy * dy)
        dx = (dx / len) * self.speed * dt
        dy = (dy / len) * self.speed * dt

        -- Move X with collision
        local nextX = self.x + dx
        if not self:collidesWithSolid(nextX, self.y, grid) then
            self.x = nextX
        end

        -- Move Y with collision
        local nextY = self.y + dy
        if not self:collidesWithSolid(self.x, nextY, grid) then
            self.y = nextY
        end

        -- Keep within virtual screen bounds
        self.x = math.clamp(self.x, 0, push:getWidth() - self.width)
        self.y = math.clamp(self.y, 0, push:getHeight() - self.height)
    end

    -- Update animation
    if self.isAttacking then
        self.currentAnimation = self.animations['attack']
    elseif self.isMoving then
        self.currentAnimation = self.animations['walk']
    else
        self.currentAnimation = self.animations['idle']
    end

    self.currentAnimation:update(dt)
end

function Hero:collidesWithSolid(x, y, grid)
    -- Check 4 corners of bounding box
    local points = {
        {x + 2, y + 2},
        {x + self.width - 2, y + 2},
        {x + 2, y + self.height - 2},
        {x + self.width - 2, y + self.height - 2}
    }

    for _, pt in ipairs(points) do
        local gx, gy = grid:worldToGrid(pt[1], pt[2])
        local tile = grid:getTile(gx, gy)
        if tile and tile:isSolid() then
            return true
        end
    end

    return false
end

function Hero:attack(playState)
    if self.attackCooldown > 0 or not self:isAlive() then return end

    self.isAttacking = true
    self.attackCooldown = self.attackCooldownMax
    self.currentAnimation = self.animations['attack']
    self.animations['attack']:gotoFrame(1)

    local slashX = self.x + self.width / 2 + (self.direction == 'left' and -20 or (self.direction == 'right' and 20 or 0))
    local slashY = self.y + self.height / 2 + (self.direction == 'up' and -20 or (self.direction == 'down' and 20 or 0))

    playState:addSlashEffect(slashX, slashY)
    gSounds['hit']:stop()
    gSounds['hit']:play()

    -- Damage nearby enemy minions
    local hitRadius = 32
    for _, minion in ipairs(playState.minions) do
        if minion:isAlive() and minion.owner == 'enemy' then
            local d = Distance(slashX, slashY, minion.x + minion.size / 2, minion.y + minion.size / 2)
            if d <= hitRadius then
                minion:takeDamage(35)
                playState:addFloatingText(minion.x, minion.y - 4, "-35", {1, 0.3, 0.3})
            end
        end
    end

    -- Damage enemy core if close
    local dCore = Distance(slashX, slashY, playState.enemyCore.x + playState.enemyCore.size / 2, playState.enemyCore.y + playState.enemyCore.size / 2)
    if dCore <= hitRadius + playState.enemyCore.size / 2 then
        playState.enemyCore:takeDamage(25)
        playState:addFloatingText(playState.enemyCore.x, playState.enemyCore.y - 8, "-25", {1, 0.2, 0.2})
    end
end

function Hero:mineOrBuild(grid, playState)
    if self.mineCooldown > 0 or not self:isAlive() then return end
    self.mineCooldown = self.mineCooldownMax

    local gx, gy = self:getTargetGridPosition(grid)
    local tile = grid:getTile(gx, gy)
    if not tile then return end

    if tile:isSolid() then
        -- Mining
        local dropType, dropAmount = grid:mineTile(gx, gy, 35)
        gSounds['mine']:stop()
        gSounds['mine']:play()
        playState:addSparks((gx - 0.5) * 32, (gy - 0.5) * 32)

        if dropType == 'gold' then
            self.gold = self.gold + dropAmount
            playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "+" .. dropAmount .. " Gold", {1, 0.85, 0.2})
        elseif dropType == 'crystal' then
            self.gold = self.gold + dropAmount
            playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "+" .. dropAmount .. " Mana Gold", {0.3, 0.9, 1})
        elseif dropType == 'stone' then
            self.stone = self.stone + dropAmount
            playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "+" .. dropAmount .. " Stone", {0.8, 0.8, 0.8})
        end
    else
        -- Building
        if self.buildSelection == 'wall' then
            if self.stone >= 5 then
                self.stone = self.stone - 5
                grid:buildTile(gx, gy, Tile.WALL)
                gSounds['build']:stop()
                gSounds['build']:play()
                playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "Wall Built", {0.8, 0.8, 0.8})
            else
                playState:addFloatingText(self.x, self.y - 12, "Need 5 Stone!", {1, 0.4, 0.4})
            end
        elseif self.buildSelection == 'turret' then
            if self.gold >= 25 and self.stone >= 10 then
                self.gold = self.gold - 25
                self.stone = self.stone - 10
                grid:buildTile(gx, gy, Tile.TURRET_PLAYER)
                gSounds['build']:stop()
                gSounds['build']:play()
                playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "Turret Built!", {0.3, 0.7, 1})
            else
                playState:addFloatingText(self.x, self.y - 12, "Need 25 Gold, 10 Stone!", {1, 0.4, 0.4})
            end
        end
    end
end

function Hero:render()
    if not self:isAlive() then return end

    -- Draw shadow
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse('fill', self.x + self.width / 2, self.y + self.height - 2, 8, 4)

    -- Invulnerability blink
    if self.invulnerable and math.floor(love.timer.getTime() * 12) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.4)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    local drawX = self.x - 3
    local drawY = self.y - 6
    local scaleX = (self.direction == 'left') and -1 or 1
    local originX = (self.direction == 'left') and 24 or 0

    self.currentAnimation:draw(gTextures['hero'], drawX + (self.direction == 'left' and 24 or 0), drawY, 0, scaleX, 1)

    -- Health bar above hero
    local hpPercent = self.health / self.maxHealth
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle('fill', self.x, self.y - 8, self.width, 3)
    love.graphics.setColor(0.2, 0.85, 0.2, 0.9)
    love.graphics.rectangle('fill', self.x, self.y - 8, self.width * hpPercent, 3)
    love.graphics.setColor(1, 1, 1, 1)
end

return Hero