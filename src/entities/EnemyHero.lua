EnemyHero = Class{}

function EnemyHero:init(x, y)
    self.x = x or 560
    self.y = y or 160
    self.width = 18
    self.height = 18
    self.speed = 105

    self.maxHealth = 130
    self.health = self.maxHealth
    self.attackPower = 22
    self.attackCooldown = 0
    self.attackCooldownMax = 0.6
    self.shiftCooldown = 0
    self.shiftCooldownMax = 6.0

    self.dimension = 'overworld' -- Dynamically shifts between Overworld & Nether
    self.direction = 'left'
    self.isMoving = false
    self.isAttacking = false
    self.invulnerable = false
    self.invulnTimer = 0
    self.respawnTimer = 0

    local g = anim8.newGrid(24, 24, gTextures['enemy_champion']:getWidth(), gTextures['enemy_champion']:getHeight())
    self.animations = {
        ['idle'] = anim8.newAnimation(g(1, 1), 1),
        ['walk'] = anim8.newAnimation(g(2, 1, 3, 1), 0.15),
        ['attack'] = anim8.newAnimation(g(4, 1), 0.2)
    }
    self.currentAnimation = self.animations['idle']
end

function EnemyHero:isAlive()
    return self.health > 0
end

function EnemyHero:takeDamage(amount)
    if self.invulnerable or not self:isAlive() then return end

    self.health = math.clamp(self.health - amount, 0, self.maxHealth)
    self.invulnerable = true
    self.invulnTimer = 0.4

    if self.health <= 0 then
        self.respawnTimer = 15.0 -- 15s respawn timer
    end
end

function EnemyHero:update(dt, grid, playState)
    if not self:isAlive() then
        if self.respawnTimer > 0 then
            self.respawnTimer = self.respawnTimer - dt
            if self.respawnTimer <= 0 then
                self.health = self.maxHealth
                self.x = 560
                self.y = 160
                self.dimension = 'overworld'
                playState:addFloatingText(self.x, self.y - 12, "Enemy Champion Respawned!", {1, 0.3, 0.3}, 'overworld')
            end
        end
        return
    end

    if self.attackCooldown > 0 then
        self.attackCooldown = self.attackCooldown - dt
        if self.attackCooldown <= 0 then
            self.isAttacking = false
        end
    end

    if self.shiftCooldown > 0 then
        self.shiftCooldown = self.shiftCooldown - dt
    end

    if self.invulnerable then
        self.invulnTimer = self.invulnTimer - dt
        if self.invulnTimer <= 0 then
            self.invulnerable = false
        end
    end

    -- Tactical Roaming & Combat AI
    local hero = playState.hero

    -- Shift dimension to contest player if player is in Nether attacking Anchor
    if hero:isAlive() and hero.dimension ~= self.dimension and self.shiftCooldown <= 0 then
        local netherAnchor = grid:getAnchor('nether', 'enemy')
        if hero.dimension == 'nether' and netherAnchor and netherAnchor.health > 0 then
            self.dimension = 'nether'
            self.shiftCooldown = self.shiftCooldownMax
            playState:addSparks(self.x + 9, self.y + 9, {1.0, 0.3, 0.7}, 'nether')
            playState:addFloatingText(self.x, self.y - 14, "[AI CHAMPION] Intercepting in Nether!", {1, 0.3, 0.7}, 'nether')
        end
    end

    -- Target: Player Hero (if same dimension), or closest Player Minion, or Player Nexus
    local targetX = 80
    local targetY = 160
    local targetEntity = nil
    local minDist = 999

    if hero:isAlive() and hero.dimension == self.dimension then
        local d = Distance(self.x, self.y, hero.x, hero.y)
        if d < 140 then
            minDist = d
            targetX = hero.x
            targetY = hero.y
            targetEntity = hero
        end
    end

    if not targetEntity then
        for _, minion in ipairs(playState.minions) do
            if minion:isAlive() and minion.owner == 'player' and minion.dimension == self.dimension then
                local d = Distance(self.x, self.y, minion.x, minion.y)
                if d < minDist then
                    minDist = d
                    targetX = minion.x
                    targetY = minion.y
                    targetEntity = minion
                end
            end
        end
    end

    -- Move or Attack
    local distToGoal = Distance(self.x + 9, self.y + 9, targetX + 9, targetY + 9)
    if targetEntity and distToGoal <= 26 then
        if self.attackCooldown <= 0 then
            self.attackCooldown = self.attackCooldownMax
            self.isAttacking = true
            self.currentAnimation = self.animations['attack']
            self.currentAnimation:gotoFrame(1)
            targetEntity:takeDamage(self.attackPower)
            playState:addSparks(targetX + 9, targetY + 9, {1, 0.3, 0.3}, self.dimension)
            gSounds['hit']:stop()
            gSounds['hit']:play()
        end
    else
        local dx = targetX - self.x
        local dy = targetY - self.y
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 1 then
            self.isMoving = true
            self.x = self.x + (dx / len) * self.speed * dt
            self.y = self.y + (dy / len) * self.speed * dt
            self.direction = (dx < 0) and 'left' or 'right'
        else
            self.isMoving = false
        end
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

function EnemyHero:render()
    if not self:isAlive() then return end

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse('fill', self.x + 9, self.y + self.height - 2, 8, 4)

    if self.invulnerable and math.floor(love.timer.getTime() * 12) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.4)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    local drawX = self.x - 3
    local drawY = self.y - 6
    local scaleX = (self.direction == 'left') and -1 or 1

    self.currentAnimation:draw(gTextures['enemy_champion'], drawX + (self.direction == 'left' and 24 or 0), drawY, 0, scaleX, 1)

    -- Health bar & Champion Title
    local hpPercent = self.health / self.maxHealth
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle('fill', self.x - 2, self.y - 8, self.width + 4, 3)
    love.graphics.setColor(0.95, 0.25, 0.25, 0.9)
    love.graphics.rectangle('fill', self.x - 2, self.y - 8, (self.width + 4) * hpPercent, 3)
    love.graphics.setColor(1, 1, 1, 1)
end

return EnemyHero
