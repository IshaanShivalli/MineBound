local Tile = require 'src.world.Tile'

Pet = Class{}

function Pet:init(owner, x, y)
    self.owner = owner or 'player' -- 'player' or 'enemy'
    self.x = x or 0
    self.y = y or 0
    self.width = 14
    self.height = 14
    self.speed = 100
    
    self.target = nil
    self.poisonCooldown = 0
    self.poisonCooldownMax = 2.0
    self.slowCooldown = 0
    self.slowCooldownMax = 3.0
    
    -- Visual animation framing / color
    self.color = (self.owner == 'player') and {0.3, 0.9, 0.4} or {0.9, 0.3, 0.3}
    self.angle = 0
end

function Pet:update(dt, playState)
    local hero = (self.owner == 'player') and playState.hero or playState.enemyHero
    if not hero or not hero:isAlive() then return end

    -- Dimension checks: Player pets do NOT work in the Nether, Opponent pets work everywhere.
    if self.owner == 'player' and hero.dimension == 'nether' then
        return
    end

    local currentDim = hero.dimension

    -- Update cooldown timers
    if self.poisonCooldown > 0 then self.poisonCooldown = self.poisonCooldown - dt end
    if self.slowCooldown > 0 then self.slowCooldown = self.slowCooldown - dt end

    -- Find target: Priority 1: Enemy Turrets to slow down, Priority 2: Opposing Hero, Priority 3: Opposing Minions
    local targetUnit = nil
    local targetDist = 200

    -- Check Enemy Turrets for slowing
    local grid = playState.grid
    local opponentTurretType = (self.owner == 'player') and Tile.TURRET_ENEMY or Tile.TURRET_PLAYER
    for y = 1, grid.rows do
        for x = 1, grid.cols do
            local tile = grid:getTile(x, y, currentDim)
            if tile and tile.type == opponentTurretType then
                local tx, ty = grid:gridToWorld(x, y)
                tx = tx + 16
                ty = ty + 16
                local d = Distance(self.x + 7, self.y + 7, tx, ty)
                if d < targetDist then
                    targetDist = d
                    targetUnit = { x = tx - 8, y = ty - 8, width = 16, height = 16, isTurret = true, tile = tile }
                end
            end
        end
    end

    -- If no turret nearby, target opposing hero
    local oppHero = (self.owner == 'player') and playState.enemyHero or playState.hero
    if not targetUnit and oppHero and oppHero:isAlive() and oppHero.dimension == currentDim then
        local d = Distance(self.x + 7, self.y + 7, oppHero.x + oppHero.width/2, oppHero.y + oppHero.height/2)
        if d < targetDist then
            targetDist = d
            targetUnit = oppHero
        end
    end

    -- If no target, follow master hero
    if not targetUnit then
        local followX = hero.x - 18
        local followY = hero.y - 10
        local distToHero = Distance(self.x, self.y, followX, followY)
        if distToHero > 24 then
            local angle = math.atan2(followY - self.y, followX - self.x)
            self.x = self.x + math.cos(angle) * self.speed * dt
            self.y = self.y + math.sin(angle) * self.speed * dt
        end
        return
    end

    -- Move towards designated target
    local tx = targetUnit.x + (targetUnit.width or 16) / 2
    local ty = targetUnit.y + (targetUnit.height or 16) / 2
    local distToTarget = Distance(self.x + 7, self.y + 7, tx, ty)

    if distToTarget > 18 then
        local angle = math.atan2(ty - (self.y + 7), tx - (self.x + 7))
        self.x = self.x + math.cos(angle) * self.speed * dt
        self.y = self.y + math.sin(angle) * self.speed * dt
    else
        -- At target! Apply features
        if targetUnit.isTurret then
            if self.slowCooldown <= 0 then
                self.slowCooldown = self.slowCooldownMax
                targetUnit.tile.shootTimer = -1.5 -- Slows down turret fire rate
                playState:addFloatingText(tx, ty - 10, "TURRET SLOWED!", {0.3, 0.8, 1.0}, currentDim)
                playState:addSparks(tx, ty, {0.3, 0.8, 1.0}, currentDim)
            end
        else
            -- Apply poison and attack damage
            if self.poisonCooldown <= 0 then
                self.poisonCooldown = self.poisonCooldownMax
                if targetUnit.takeDamage then
                    targetUnit:takeDamage(12)
                    playState:addFloatingText(tx, ty - 10, "PET POISON! (-12)", {0.4, 0.9, 0.3}, currentDim)
                    playState:addSparks(tx, ty, {0.4, 0.9, 0.3}, currentDim)
                end
            end
        end
    end
end

function Pet:render(playState)
    local hero = (self.owner == 'player') and playState.hero or playState.enemyHero
    if not hero or (self.owner == 'player' and hero.dimension == 'nether') then
        return
    end

    if hero.dimension ~= playState.hero.dimension then
        return
    end

    -- Draw Pet Spirit Orb / Companion
    local pulse = (math.sin(love.timer.getTime() * 8) + 1) * 0.5
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.85)
    love.graphics.circle('fill', self.x + 7, self.y + 7, 6 + pulse * 2)
    
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle('fill', self.x + 5, self.y + 5, 2)

    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.3)
    love.graphics.circle('line', self.x + 7, self.y + 7, 9 + pulse * 2)
    
    love.graphics.setColor(1, 1, 1, 1)
end

return Pet
