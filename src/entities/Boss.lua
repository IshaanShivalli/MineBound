Boss = Class{}

function Boss:init(x, y)
    self.x = x or 320
    self.y = y or 240
    self.width = 48
    self.height = 48
    self.maxHealth = 450
    self.health = self.maxHealth
    self.speed = 35
    self.attackPower = 20
    self.attackTimer = 0
    self.attackInterval = 1.6
    self.aggroRange = 110
    self.attackRange = 36

    self.dimension = 'nether' -- The Void Golem resides in Nether Jungle Camp
    self.hitFlash = 0
    self.isAttacking = false
    self.facing = 'left'

    local g = anim8.newGrid(48, 48, gTextures['boss_golem']:getWidth(), gTextures['boss_golem']:getHeight())
    self.animations = {
        ['idle'] = anim8.newAnimation(g(1, 1), 1),
        ['attack'] = anim8.newAnimation(g('1-2', 1), 0.3)
    }
    self.currentAnimation = self.animations['idle']
end

function Boss:isAlive()
    return self.health > 0
end

function Boss:takeDamage(amount, attacker)
    if not self:isAlive() then return end

    self.health = math.clamp(self.health - amount, 0, self.maxHealth)
    self.hitFlash = 0.2
    gSounds['hit']:stop()
    gSounds['hit']:play()

    if self.health <= 0 then
        self:onDefeated(attacker)
    end
end

function Boss:onDefeated(attacker)
    -- Grant Team Buff to Player Hero
    if attacker then
        attacker.voidFuryTimer = 25.0 -- 25 seconds of Void Fury (+50% DMG, +25% SPD)
    end
end

function Boss:update(dt, playState)
    if not self:isAlive() then return end

    if self.hitFlash > 0 then
        self.hitFlash = self.hitFlash - dt
    end

    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end

    local hero = playState.hero
    local cx = self.x + self.width / 2
    local cy = self.y + self.height / 2

    -- Check if Hero or Enemy Champion is in Nether near boss lair
    local target = nil
    local targetX = cx
    local targetY = cy

    if hero:isAlive() and hero.dimension == 'nether' then
        local d = Distance(cx, cy, hero.x + 9, hero.y + 9)
        if d < self.aggroRange then
            target = hero
            targetX = hero.x + 9
            targetY = hero.y + 9
        end
    end

    if not target and playState.enemyHero and playState.enemyHero:isAlive() and playState.enemyHero.dimension == 'nether' then
        local d = Distance(cx, cy, playState.enemyHero.x + 9, playState.enemyHero.y + 9)
        if d < self.aggroRange then
            target = playState.enemyHero
            targetX = playState.enemyHero.x + 9
            targetY = playState.enemyHero.y + 9
        end
    end

    if target then
        local dist = Distance(cx, cy, targetX, targetY)
        if dist <= self.attackRange then
            -- Attack
            if self.attackTimer <= 0 then
                self.attackTimer = self.attackInterval
                self.isAttacking = true
                self.currentAnimation = self.animations['attack']
                self.currentAnimation:gotoFrame(1)
                target:takeDamage(self.attackPower)
                playState:addSparks(targetX, targetY, {1.0, 0.2, 0.8}, 'nether')
                playState:triggerScreenShake(4, 0.2)
            end
        else
            -- Move toward target
            local dx = targetX - cx
            local dy = targetY - cy
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 1 then
                self.x = self.x + (dx / len) * self.speed * dt
                self.y = self.y + (dy / len) * self.speed * dt
                self.facing = (dx < 0) and 'left' or 'right'
            end
            self.currentAnimation = self.animations['idle']
        end
    else
        self.currentAnimation = self.animations['idle']
    end

    self.currentAnimation:update(dt)
end

function Boss:render()
    if not self:isAlive() then return end

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.ellipse('fill', self.x + self.width / 2, self.y + self.height - 4, 20, 8)

    if self.hitFlash > 0 then
        love.graphics.setColor(1, 0.4, 0.4, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    local scaleX = (self.facing == 'left') and 1 or -1
    local originX = (self.facing == 'left') and 0 or 48

    self.currentAnimation:draw(gTextures['boss_golem'], self.x + originX, self.y, 0, scaleX, 1)

    -- Boss Health Bar & Title
    local hpPercent = self.health / self.maxHealth
    love.graphics.setColor(0.1, 0.1, 0.1, 0.85)
    love.graphics.rectangle('fill', self.x - 6, self.y - 14, self.width + 12, 6)
    love.graphics.setColor(0.8, 0.2, 1.0, 0.95)
    love.graphics.rectangle('fill', self.x - 6, self.y - 14, (self.width + 12) * hpPercent, 6)

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf("ANCIENT VOID GOLEM", self.x - 30, self.y - 25, self.width + 60, 'center')
    love.graphics.setColor(1, 1, 1, 1)
end

return Boss
