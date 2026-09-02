local Tile = require 'src.world.Tile'

Hero = Class{}

function Hero:init(x, y)
    self.x = x or 64
    self.y = y or 160
    self.width = 18
    self.height = 18
    self.baseSpeed = 120
    self.speed = self.baseSpeed

    self.baseMaxHealth = 100
    self.maxHealth = self.baseMaxHealth
    self.health = self.maxHealth
    self.gold = 50
    self.stone = 30
    self.voidEssence = 20

    self.baseAttackPower = 35
    self.attackPower = self.baseAttackPower

    self.dimension = 'overworld' -- 'overworld' or 'nether'
    self.shiftCooldown = 0
    self.shiftCooldownMax = 1.0

    -- Abilities Cooldowns
    self.dashCooldown = 0
    self.dashCooldownMax = 4.0
    self.isDashing = false
    self.dashTimer = 0

    self.ultCooldown = 0
    self.ultCooldownMax = 14.0

    -- Buffs
    self.voidFuryTimer = 0

    -- Upgrades Purchased
    self.upgrades = {
        blades = 0,
        boots = 0,
        armor = 0,
        turrets = 0
    }

    self.direction = 'right'
    self.isMoving = false
    self.isAttacking = false
    self.attackCooldown = 0
    self.attackCooldownMax = 0.25

    self.mineCooldown = 0
    self.mineCooldownMax = 0.25

    self.invulnerable = false
    self.invulnTimer = 0

    self.buildSelection = 'wall' -- 'wall', 'turret', 'anchor', 'healer'

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

function Hero:applyUpgrade(upgradeType)
    if upgradeType == 'blades' then
        self.upgrades.blades = self.upgrades.blades + 1
        self.attackPower = self.baseAttackPower + self.upgrades.blades * 12
    elseif upgradeType == 'boots' then
        self.upgrades.boots = self.upgrades.boots + 1
        self.speed = self.baseSpeed + self.upgrades.boots * 22
    elseif upgradeType == 'armor' then
        self.upgrades.armor = self.upgrades.armor + 1
        self.maxHealth = self.baseMaxHealth + self.upgrades.armor * 40
        self.health = self.health + 40
    elseif upgradeType == 'turrets' then
        self.upgrades.turrets = self.upgrades.turrets + 1
    end
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

function Hero:shiftDimension(grid, playState)
    if self.shiftCooldown > 0 or not self:isAlive() then return end

    local targetDim = (self.dimension == 'overworld') and 'nether' or 'overworld'
    
    if self:collidesWithSolid(self.x, self.y, grid, targetDim) then
        playState:addFloatingText(self.x, self.y - 12, "Material Collision in " .. targetDim:upper() .. "!", {1, 0.4, 0.4}, self.dimension)
        return
    end

    self.dimension = targetDim
    self.shiftCooldown = self.shiftCooldownMax

    gSounds['shift']:stop()
    gSounds['shift']:play()

    playState:triggerDimensionShift(self.dimension)
    local text = (self.dimension == 'nether') and ">> ENTERING NETHER REALM <<" or ">> RETURNING TO OVERWORLD <<"
    local col = (self.dimension == 'nether') and {0.9, 0.4, 1.0} or {0.4, 0.9, 1.0}
    playState:addFloatingText(self.x - 10, self.y - 16, text, col, self.dimension)
end

-- Ability 1: Void Dash (E Key)
function Hero:castDash(grid, playState)
    if self.dashCooldown > 0 or not self:isAlive() then return end

    self.dashCooldown = self.dashCooldownMax
    self.isDashing = true
    self.dashTimer = 0.18
    self.invulnerable = true
    self.invulnTimer = 0.35

    gSounds['dash']:stop()
    gSounds['dash']:play()

    local dashDist = 70
    local dx = (self.direction == 'left' and -dashDist) or (self.direction == 'right' and dashDist) or 0
    local dy = (self.direction == 'up' and -dashDist) or (self.direction == 'down' and dashDist) or 0

    -- Test intermediate steps for collision
    local targetX = self.x + dx
    local targetY = self.y + dy

    if not self:collidesWithSolid(targetX, targetY, grid, self.dimension) then
        self.x = targetX
        self.y = targetY
    end

    playState:triggerScreenShake(3, 0.15)
    playState:addSparks(self.x + 9, self.y + 9, {0.9, 0.3, 1.0}, self.dimension)
    playState:addFloatingText(self.x, self.y - 14, "VOID DASH!", {0.9, 0.4, 1.0}, self.dimension)
end

-- Ability 2: Dimensional Shockwave Ultimate (R Key)
function Hero:castUltimate(grid, playState)
    if self.ultCooldown > 0 or not self:isAlive() then return end

    self.ultCooldown = self.ultCooldownMax
    gSounds['ult']:stop()
    gSounds['ult']:play()

    playState:triggerScreenShake(8, 0.45)

    local cx = self.x + self.width / 2
    local cy = self.y + self.height / 2
    local blastRadius = 90
    local ultDmg = 80 + (self.voidFuryTimer > 0 and 40 or 0)

    -- Primary Realm Blast
    playState:addSlashEffect(cx, cy, self.dimension)
    playState:addSparks(cx, cy, {1.0, 0.8, 0.2}, self.dimension)

    for _, minion in ipairs(playState.minions) do
        if minion:isAlive() and minion.owner == 'enemy' and minion.dimension == self.dimension then
            local d = Distance(cx, cy, minion.x + minion.size / 2, minion.y + minion.size / 2)
            if d <= blastRadius then
                minion:takeDamage(ultDmg)
                playState:addFloatingText(minion.x, minion.y - 8, "-" .. ultDmg .. " CRIT!", {1, 0.2, 0.2}, self.dimension)
            end
        end
    end

    -- Damage Enemy Champion if in range
    if playState.enemyHero and playState.enemyHero:isAlive() and playState.enemyHero.dimension == self.dimension then
        local d = Distance(cx, cy, playState.enemyHero.x + 9, playState.enemyHero.y + 9)
        if d <= blastRadius then
            playState.enemyHero:takeDamage(ultDmg)
            playState:addFloatingText(playState.enemyHero.x, playState.enemyHero.y - 12, "-" .. ultDmg .. " ULT!", {1, 0.2, 0.2}, self.dimension)
        end
    end

    -- Damage Boss if in range
    if playState.boss and playState.boss:isAlive() and self.dimension == 'nether' then
        local d = Distance(cx, cy, playState.boss.x + 24, playState.boss.y + 24)
        if d <= blastRadius + 24 then
            playState.boss:takeDamage(ultDmg, self)
        end
    end

    -- Cross-Dimensional Echo: Pulses 50% damage through into the other realm!
    local otherDim = (self.dimension == 'overworld') and 'nether' or 'overworld'
    playState:addSparks(cx, cy, {0.9, 0.3, 1.0}, otherDim)
    for _, minion in ipairs(playState.minions) do
        if minion:isAlive() and minion.owner == 'enemy' and minion.dimension == otherDim then
            local d = Distance(cx, cy, minion.x + minion.size / 2, minion.y + minion.size / 2)
            if d <= blastRadius then
                minion:takeDamage(math.floor(ultDmg * 0.5))
                playState:addFloatingText(minion.x, minion.y - 8, "-" .. math.floor(ultDmg * 0.5) .. " ECHO!", {0.9, 0.4, 1.0}, otherDim)
            end
        end
    end

    playState:addFloatingText(self.x - 20, self.y - 18, "DIMENSIONAL SHOCKWAVE!", {1.0, 0.85, 0.2}, self.dimension)
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

    if self.shiftCooldown > 0 then
        self.shiftCooldown = self.shiftCooldown - dt
    end

    if self.dashCooldown > 0 then
        self.dashCooldown = self.dashCooldown - dt
    end

    if self.ultCooldown > 0 then
        self.ultCooldown = self.ultCooldown - dt
    end

    if self.voidFuryTimer > 0 then
        self.voidFuryTimer = self.voidFuryTimer - dt
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
        local currentSpd = self.speed * (self.voidFuryTimer > 0 and 1.25 or 1.0)
        local len = math.sqrt(dx * dx + dy * dy)
        dx = (dx / len) * currentSpd * dt
        dy = (dy / len) * currentSpd * dt

        local nextX = self.x + dx
        if not self:collidesWithSolid(nextX, self.y, grid, self.dimension) then
            self.x = nextX
        end

        local nextY = self.y + dy
        if not self:collidesWithSolid(self.x, nextY, grid, self.dimension) then
            self.y = nextY
        end

        self.x = math.clamp(self.x, 0, push:getWidth() - self.width)
        self.y = math.clamp(self.y, 0, push:getHeight() - self.height)
    end

    local gx, gy = self:getGridPosition(grid)
    local curTile = grid:getTile(gx, gy, self.dimension)
    if curTile and curTile.type == Tile.RIFT_PORTAL and self.shiftCooldown <= 0 then
        playState.riftNearby = true
    else
        playState.riftNearby = false
    end

    if self.isAttacking then
        self.currentAnimation = self.animations['attack']
    elseif self.isMoving then
        self.currentAnimation = self.animations['walk']
    else
        self.currentAnimation = self.animations['idle']
    end

    self.currentAnimation:update(dt)
end

function Hero:collidesWithSolid(x, y, grid, dimension)
    dimension = dimension or self.dimension
    local points = {
        {x + 2, y + 2},
        {x + self.width - 2, y + 2},
        {x + 2, y + self.height - 2},
        {x + self.width - 2, y + self.height - 2}
    }

    for _, pt in ipairs(points) do
        local gx, gy = grid:worldToGrid(pt[1], pt[2])
        local tile = grid:getTile(gx, gy, dimension)
        if tile and tile:isSolid() then
            return true
        end
    end

    return false
end

function Hero:isIntersectingTile(gx, gy)
    local tileLeft = (gx - 1) * 32
    local tileRight = gx * 32
    local tileTop = (gy - 1) * 32
    local tileBottom = gy * 32

    local heroLeft = self.x
    local heroRight = self.x + self.width
    local heroTop = self.y
    local heroBottom = self.y + self.height

    return not (heroRight <= tileLeft or heroLeft >= tileRight or heroBottom <= tileTop or heroTop >= tileBottom)
end

function Hero:attack(playState)
    if self.attackCooldown > 0 or not self:isAlive() then return end

    self.isAttacking = true
    self.attackCooldown = self.attackCooldownMax
    self.currentAnimation = self.animations['attack']
    self.animations['attack']:gotoFrame(1)

    local slashX = self.x + self.width / 2 + (self.direction == 'left' and -20 or (self.direction == 'right' and 20 or 0))
    local slashY = self.y + self.height / 2 + (self.direction == 'up' and -20 or (self.direction == 'down' and 20 or 0))

    playState:addSlashEffect(slashX, slashY, self.dimension)
    gSounds['hit']:stop()
    gSounds['hit']:play()

    local hitRadius = 32
    local currentDmg = self.attackPower * (self.voidFuryTimer > 0 and 1.5 or 1.0)

    -- Damage nearby enemy minions
    for _, minion in ipairs(playState.minions) do
        if minion:isAlive() and minion.owner == 'enemy' and minion.dimension == self.dimension then
            local d = Distance(slashX, slashY, minion.x + minion.size / 2, minion.y + minion.size / 2)
            if d <= hitRadius then
                minion:takeDamage(currentDmg)
                playState:addFloatingText(minion.x, minion.y - 4, "-" .. math.floor(currentDmg), {1, 0.3, 0.3}, self.dimension)
            end
        end
    end

    -- Damage Enemy Champion
    if playState.enemyHero and playState.enemyHero:isAlive() and playState.enemyHero.dimension == self.dimension then
        local d = Distance(slashX, slashY, playState.enemyHero.x + 9, playState.enemyHero.y + 9)
        if d <= hitRadius + 9 then
            playState.enemyHero:takeDamage(currentDmg)
            playState:addFloatingText(playState.enemyHero.x, playState.enemyHero.y - 10, "-" .. math.floor(currentDmg), {1, 0.2, 0.2}, self.dimension)
        end
    end

    -- Damage Void Golem Boss
    if playState.boss and playState.boss:isAlive() and self.dimension == 'nether' then
        local d = Distance(slashX, slashY, playState.boss.x + 24, playState.boss.y + 24)
        if d <= hitRadius + 24 then
            playState.boss:takeDamage(currentDmg, self)
        end
    end

    -- Damage enemy core if in Overworld
    if self.dimension == 'overworld' then
        local dCore = Distance(slashX, slashY, playState.enemyCore.x + playState.enemyCore.size / 2, playState.enemyCore.y + playState.enemyCore.size / 2)
        if dCore <= hitRadius + playState.enemyCore.size / 2 then
            local enemyAnchor = playState.grid:getAnchor('nether', 'enemy')
            local dmg = enemyAnchor and math.floor(currentDmg * 0.5) or currentDmg
            playState.enemyCore:takeDamage(dmg)
            if enemyAnchor then
                playState:addFloatingText(playState.enemyCore.x, playState.enemyCore.y - 8, "-" .. dmg .. " (Shielded!)", {0.8, 0.5, 1}, 'overworld')
            else
                playState:addFloatingText(playState.enemyCore.x, playState.enemyCore.y - 8, "-" .. dmg, {1, 0.2, 0.2}, 'overworld')
            end
        end
    else
        -- In Nether: Damage Enemy Nether Anchor
        local gx, gy = playState.grid:worldToGrid(slashX, slashY)
        local tile = playState.grid:getTile(gx, gy, 'nether')
        if tile and tile.type == Tile.NETHER_ANCHOR_ENEMY then
            tile:takeDamage(currentDmg)
            playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "-" .. math.floor(currentDmg) .. " Anchor", {1, 0.4, 0.8}, 'nether')
            playState:addSparks((gx - 0.5) * 32, (gy - 0.5) * 32, {1, 0.3, 0.8}, 'nether')
        end
    end
end

function Hero:mineOrBuild(grid, playState)
    if self.mineCooldown > 0 or not self:isAlive() then return end
    self.mineCooldown = self.mineCooldownMax

    local gx, gy = self:getTargetGridPosition(grid)
    local tile = grid:getTile(gx, gy, self.dimension)
    if not tile then return end

    if tile:isSolid() then
        local dropType, dropAmount = grid:mineTile(gx, gy, 35, self.dimension)
        gSounds['mine']:stop()
        gSounds['mine']:play()
        playState:addSparks((gx - 0.5) * 32, (gy - 0.5) * 32, nil, self.dimension)

        if dropType == 'gold' then
            self.gold = self.gold + dropAmount
            playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "+" .. dropAmount .. " Coins", {1, 0.85, 0.2}, self.dimension)
        elseif dropType == 'stone' then
            self.stone = self.stone + dropAmount
            playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "+" .. dropAmount .. " Ores", {0.8, 0.8, 0.8}, self.dimension)
        elseif dropType == 'void_essence' then
            self.voidEssence = self.voidEssence + dropAmount
            playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "+" .. dropAmount .. " Gems", {0.9, 0.4, 1.0}, self.dimension)
        end
    else
        if self:isIntersectingTile(gx, gy) then
            playState:addFloatingText(self.x, self.y - 12, "Step away to build!", {1, 0.5, 0.2}, self.dimension)
            return
        end

        if self.buildSelection == 'wall' then
            if self.stone >= 5 then
                self.stone = self.stone - 5
                local wallType = (self.dimension == 'nether') and Tile.VOID_WALL or Tile.WALL
                grid:buildTile(gx, gy, wallType, self.dimension)
                gSounds['build']:stop()
                gSounds['build']:play()
                playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "Wall Built", {0.8, 0.8, 0.8}, self.dimension)
            else
                playState:addFloatingText(self.x, self.y - 12, "Need 5 Ores!", {1, 0.4, 0.4}, self.dimension)
            end
        elseif self.buildSelection == 'turret' then
            if self.gold >= 25 and self.stone >= 10 then
                self.gold = self.gold - 25
                self.stone = self.stone - 10
                grid:buildTile(gx, gy, Tile.TURRET_PLAYER, self.dimension)
                gSounds['build']:stop()
                gSounds['build']:play()
                playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "Turret Built!", {0.3, 0.7, 1}, self.dimension)
            else
                playState:addFloatingText(self.x, self.y - 12, "Need 25 Coins, 10 Ores!", {1, 0.4, 0.4}, self.dimension)
            end
        elseif self.buildSelection == 'anchor' then
            if self.voidEssence >= 30 and self.gold >= 20 then
                self.voidEssence = self.voidEssence - 30
                self.gold = self.gold - 20
                grid:buildTile(gx, gy, Tile.NETHER_ANCHOR_PLAYER, self.dimension)
                gSounds['build']:stop()
                gSounds['build']:play()
                playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "Void Anchor Built!", {0.9, 0.4, 1.0}, self.dimension)
            else
                playState:addFloatingText(self.x, self.y - 12, "Need 30 Gems, 20 Coins!", {1, 0.4, 0.4}, self.dimension)
            end
        elseif self.buildSelection == 'healer' then
            if self.gold >= 50 and self.stone >= 60 and self.voidEssence >= 20 then
                self.gold = self.gold - 50
                self.stone = self.stone - 60
                self.voidEssence = self.voidEssence - 20
                grid:buildTile(gx, gy, Tile.HEALING_CHAMBER, self.dimension)
                gSounds['build']:stop()
                gSounds['build']:play()
                playState:addFloatingText((gx - 0.5) * 32, (gy - 0.5) * 32, "Healing Chamber Built!", {0.2, 1.0, 0.5}, self.dimension)
            else
                playState:addFloatingText(self.x, self.y - 12, "Need 50 Coins, 60 Ores, 20 Gems!", {1, 0.4, 0.4}, self.dimension)
            end
        end
    end
end

function Hero:render()
    if not self:isAlive() then return end

    -- Draw shadow
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse('fill', self.x + self.width / 2, self.y + self.height - 2, 8, 4)

    -- Void Fury Golden/Purple Aura
    if self.voidFuryTimer > 0 then
        local pulse = (math.sin(love.timer.getTime() * 10) + 1) * 0.5
        love.graphics.setColor(1.0, 0.8, 0.2, 0.35 + pulse * 0.25)
        love.graphics.circle('line', self.x + self.width / 2, self.y + self.height / 2, 16 + pulse * 3)
    end

    -- Dimension aura / tint
    if self.dimension == 'nether' then
        love.graphics.setColor(0.9, 0.4, 1.0, 0.3)
        love.graphics.circle('fill', self.x + self.width / 2, self.y + self.height / 2, 14)
    end

    -- Invulnerability blink
    if self.invulnerable and math.floor(love.timer.getTime() * 12) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.4)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    local drawX = self.x - 3
    local drawY = self.y - 6
    local scaleX = (self.direction == 'left') and -1 or 1

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