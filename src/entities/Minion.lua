Minion = Class{}

function Minion:init(x, y, owner, targetCore, dimension)
    self.x = x
    self.y = y
    self.size = 16
    self.owner = owner or 'player'
    self.targetCore = targetCore
    self.dimension = dimension or 'overworld' -- 'overworld' or 'nether'
    self.speed = (self.dimension == 'nether') and 55 or 45
    self.maxHealth = (self.dimension == 'nether') and 50 or 40
    self.health = self.maxHealth
    self.attackPower = (self.dimension == 'nether') and 12 or 8
    self.attackTimer = 0
    self.attackInterval = 1.0
    self.aggroRange = 65
    self.attackRange = 18

    local texKey
    if self.dimension == 'nether' then
        texKey = (self.owner == 'player') and 'minion_void_player' or 'minion_void_enemy'
    else
        texKey = (self.owner == 'player') and 'minion_player' or 'minion_enemy'
    end

    local texture = gTextures[texKey]
    local g = anim8.newGrid(16, 16, texture:getWidth(), texture:getHeight())
    self.walkAnimation = anim8.newAnimation(g('1-2', 1), 0.2)
    self.facing = (self.owner == 'player') and 'right' or 'left'
end

function Minion:isAlive()
    return self.health > 0
end

function Minion:takeDamage(amount)
    self.health = math.clamp(self.health - amount, 0, self.maxHealth)
    return self.health <= 0
end

function Minion:update(dt, playState)
    if not self:isAlive() then return end

    self.walkAnimation:update(dt)

    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end

    -- Find target in same dimension: enemy minions, enemy hero, or target core / anchor
    local target = nil
    local targetX = self.targetCore.x + self.targetCore.size / 2
    local targetY = self.targetCore.y + self.targetCore.size / 2
    local closestDist = self.aggroRange

    -- Check enemy minions in same dimension
    for _, other in ipairs(playState.minions) do
        if other:isAlive() and other.dimension == self.dimension and other.owner ~= self.owner then
            local d = Distance(self.x, self.y, other.x, other.y)
            if d < closestDist then
                closestDist = d
                target = other
                targetX = other.x + other.size / 2
                targetY = other.y + other.size / 2
            end
        end
    end

    -- If enemy minion and player hero is near in same dimension, target hero
    if self.owner == 'enemy' and playState.hero:isAlive() and playState.hero.dimension == self.dimension then
        local d = Distance(self.x, self.y, playState.hero.x, playState.hero.y)
        if d < closestDist then
            target = playState.hero
            targetX = playState.hero.x + playState.hero.width / 2
            targetY = playState.hero.y + playState.hero.height / 2
        end
    end

    -- If in Overworld and close to target core
    if self.dimension == 'overworld' then
        local coreDist = Distance(self.x, self.y, self.targetCore.x + self.targetCore.size / 2, self.targetCore.y + self.targetCore.size / 2)
        if not target and coreDist <= self.attackRange + self.targetCore.size / 2 then
            target = self.targetCore
        end
    end

    -- Attack or Move
    local distToGoal = Distance(self.x + self.size / 2, self.y + self.size / 2, targetX, targetY)

    if target and distToGoal <= self.attackRange + (target.size or target.width or 16) / 2 then
        -- In attack range
        if self.attackTimer <= 0 then
            self.attackTimer = self.attackInterval
            target:takeDamage(self.attackPower)
            playState:addSparks(self.x + self.size / 2, self.y + self.size / 2, (self.dimension == 'nether') and {0.9, 0.4, 1} or {1, 0.8, 0.2})
            gSounds['hit']:stop()
            gSounds['hit']:play()
        end
    else
        -- Move toward target
        local dx = targetX - (self.x + self.size / 2)
        local dy = targetY - (self.y + self.size / 2)
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 1 then
            dx = (dx / len) * self.speed * dt
            dy = (dy / len) * self.speed * dt
            self.x = self.x + dx
            self.y = self.y + dy
            self.facing = (dx < 0) and 'left' or 'right'
        end
    end
end

function Minion:render()
    if not self:isAlive() then return end

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse('fill', self.x + self.size / 2, self.y + self.size - 1, 6, 3)

    love.graphics.setColor(1, 1, 1, 1)
    local texKey
    if self.dimension == 'nether' then
        texKey = (self.owner == 'player') and 'minion_void_player' or 'minion_void_enemy'
    else
        texKey = (self.owner == 'player') and 'minion_player' or 'minion_enemy'
    end

    local texture = gTextures[texKey]
    local scaleX = (self.facing == 'left') and -1 or 1

    self.walkAnimation:draw(texture, self.x + (self.facing == 'left' and 16 or 0), self.y, 0, scaleX, 1)

    -- Health bar
    local hpPercent = self.health / self.maxHealth
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle('fill', self.x, self.y - 4, self.size, 2)
    local col = (self.owner == 'player') and {0.2, 0.8, 0.2} or {0.9, 0.3, 0.3}
    if self.dimension == 'nether' then
        col = (self.owner == 'player') and {0.7, 0.3, 1.0} or {1.0, 0.3, 0.7}
    end
    love.graphics.setColor(col[1], col[2], col[3], 0.9)
    love.graphics.rectangle('fill', self.x, self.y - 4, self.size * hpPercent, 2)
    love.graphics.setColor(1, 1, 1, 1)
end

return Minion