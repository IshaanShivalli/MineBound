local Minion = require 'src.entities.Minion'

Core = Class{}

function Core:init(x, y, owner, maxHealth)
    self.x = x
    self.y = y
    self.size = 32
    self.owner = owner or 'player'
    self.maxHealth = maxHealth or 400
    self.health = self.maxHealth
    self.spawnTimer = 2.0
    self.spawnInterval = 7.0
    self.hitFlash = 0
end

function Core:isDestroyed()
    return self.health <= 0
end

function Core:takeDamage(amount)
    if self:isDestroyed() then return end

    self.health = math.clamp(self.health - amount, 0, self.maxHealth)
    self.hitFlash = 0.2

    gSounds['core_hit']:stop()
    gSounds['core_hit']:play()
end

function Core:update(dt, playState)
    if self:isDestroyed() then return end

    if self.hitFlash > 0 then
        self.hitFlash = self.hitFlash - dt
    end

    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnInterval then
        self.spawnTimer = 0
        self:spawnWave(playState)
    end
end

function Core:spawnWave(playState)
    local targetCore = (self.owner == 'player') and playState.enemyCore or playState.playerCore
    local spawnOffset = (self.owner == 'player') and 36 or -24

    -- Spawn standard Overworld minions
    local m1 = Minion(self.x + spawnOffset, self.y - 32, self.owner, targetCore, 'overworld')
    local m2 = Minion(self.x + spawnOffset, self.y + 32, self.owner, targetCore, 'overworld')
    table.insert(playState.minions, m1)
    table.insert(playState.minions, m2)

    -- If Nether Anchor is alive for this team, also summon a Void Creep into Nether Realm!
    local anchor = playState.grid:getAnchor('nether', self.owner)
    if anchor and anchor.health > 0 then
        local vm = Minion(self.x + spawnOffset, self.y, self.owner, targetCore, 'nether')
        table.insert(playState.minions, vm)
    end

    playState:addSparks(self.x + self.size / 2, self.y + self.size / 2)
end

function Core:render(playState)
    local frameIndex = (self.owner == 'player') and 7 or 8

    -- Core Base & Crystal Sprite
    if self.hitFlash > 0 then
        love.graphics.setColor(1, 0.4, 0.4, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.draw(gTextures['tileset'], gFrames['tiles'][frameIndex], self.x, self.y)

    -- Check if Anchor Shield is active
    local hasAnchor = playState and playState.grid:getAnchor('nether', self.owner)
    local pulse = (math.sin(love.timer.getTime() * 4) + 1) * 0.5

    if hasAnchor then
        -- Dimensional Shield Dome
        love.graphics.setColor(0.8, 0.3, 1.0, 0.35 + pulse * 0.25)
        love.graphics.circle('line', self.x + self.size / 2, self.y + self.size / 2, 22 + pulse * 3)
        love.graphics.setColor(0.9, 0.5, 1.0, 0.15)
        love.graphics.circle('fill', self.x + self.size / 2, self.y + self.size / 2, 22 + pulse * 3)
    else
        -- Standard Energy Glow
        if self.owner == 'player' then
            love.graphics.setColor(0.3, 0.7, 1, 0.25 + pulse * 0.25)
        else
            love.graphics.setColor(1, 0.3, 0.3, 0.25 + pulse * 0.25)
        end
        love.graphics.circle('line', self.x + self.size / 2, self.y + self.size / 2, 18 + pulse * 4)
    end

    -- Health Bar & Label
    local hpPercent = self.health / self.maxHealth
    love.graphics.setColor(0.1, 0.1, 0.1, 0.85)
    love.graphics.rectangle('fill', self.x - 4, self.y - 12, self.size + 8, 6)

    love.graphics.setColor(self.owner == 'player' and {0.2, 0.6, 1} or {1, 0.25, 0.25}, 1)
    love.graphics.rectangle('fill', self.x - 4, self.y - 12, (self.size + 8) * hpPercent, 6)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(gFonts['small'])
    local label = self.owner == 'player' and 'PLAYER NEXUS' or 'ENEMY NEXUS'
    if hasAnchor then
        label = label .. " [SHIELDED]"
    end
    love.graphics.printf(label, self.x - 30, self.y - 22, self.size + 60, 'center')

    love.graphics.setColor(1, 1, 1, 1)
end

return Core