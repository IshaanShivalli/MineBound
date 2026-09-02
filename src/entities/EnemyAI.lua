local Tile = require 'src.world.Tile'
local GGUF = require 'lib.GGUF'

EnemyAI = Class{}

function EnemyAI:init(playState)
    self.playState = playState
    self.decisionTimer = 0
    self.decisionInterval = 2.0 -- Evaluate tactical decisions every 2.0s

    -- AI Resources
    self.gold = 50
    self.stone = 40
    self.voidEssence = 30

    -- Tactical realm state: AI operates primarily in the Nether / Underworld Realm
    self.realm = 'nether'
    self.modelPath = 'assets/models/enemy_ai_model.gguf'
    self.ggufModel = GGUF(self.modelPath)

    self.modelStatus = self.ggufModel.loaded and "GGUF Model Active (" .. (self.ggufModel.metadata['general.name'] or 'AI') .. ")" or "Heuristic Mode"
    print("[AI Initialization] " .. self.modelStatus)
end

function EnemyAI:update(dt)
    -- Passive AI income from realm harvesting
    self.gold = self.gold + dt * 3.5
    self.stone = self.stone + dt * 2.5
    self.voidEssence = self.voidEssence + dt * 2.0

    self.decisionTimer = self.decisionTimer + dt
    if self.decisionTimer >= self.decisionInterval then
        self.decisionTimer = 0
        self:evaluateTactics()
    end
end

function EnemyAI:evaluateTactics()
    local playState = self.playState
    local grid = playState.grid
    local hero = playState.hero

    local netherAnchor = grid:getAnchor('nether', 'enemy')
    local heroInNether = hero:isAlive() and hero.dimension == 'nether'
    local distToAnchor = 999
    if netherAnchor then
        distToAnchor = Distance(hero.x, hero.y, (netherAnchor.gridX - 0.5) * 32, (netherAnchor.gridY - 0.5) * 32)
    end

    -- Construct state vector for GGUF model
    local stateVector = {
        heroDimension = hero.dimension,
        anchorHealth = netherAnchor and netherAnchor.health or 0,
        heroDistToAnchor = distToAnchor,
        gold = self.gold,
        stone = self.stone,
        voidEssence = self.voidEssence
    }

    -- Run GGUF Model Inference
    local action = 1
    if self.ggufModel and self.ggufModel.loaded then
        action = self.ggufModel:predictTactics(stateVector)
    end

    -- Action 1: Fortify Obsidian Wall in Nether
    if action == 1 then
        if self.voidEssence >= 10 and self.stone >= 5 then
            self:fortifyNetherChokepoints(grid, hero)
        end
    -- Action 2: Deploy Nether Void Turret
    elseif action == 2 then
        if self.gold >= 25 and self.stone >= 10 then
            self:buildNetherTurret(grid)
        end
    -- Action 3: Deploy Underworld Healing Sanctuary
    elseif action == 3 then
        if self.gold >= 50 and self.stone >= 60 and self.voidEssence >= 20 then
            self:buildNetherHealingChamber(grid)
        end
    -- Action 4: Rebuild Nether Anchor
    elseif action == 4 then
        if (not netherAnchor or netherAnchor.health <= 0) and self.voidEssence >= 30 and self.gold >= 20 then
            self:rebuildNetherAnchor(grid)
        end
    end
end

function EnemyAI:fortifyNetherChokepoints(grid, hero)
    local candidateSpots = {
        {18, 5}, {18, 7}, {17, 6}, {16, 5}, {16, 7}, {19, 4}, {19, 8}
    }

    for _, spot in ipairs(candidateSpots) do
        local x, y = spot[1], spot[2]
        local tile = grid:getTile(x, y, 'nether')
        if tile and tile.type == Tile.VOID_FLOOR then
            self.voidEssence = self.voidEssence - 10
            self.stone = self.stone - 5
            grid:buildTile(x, y, Tile.VOID_WALL, 'nether')
            self.playState:addFloatingText((x - 0.5) * 32, (y - 0.5) * 32, "[GGUF AI] Obsidian Wall!", {1, 0.4, 0.7}, 'nether')
            if hero.dimension == 'nether' then
                gSounds['build']:stop()
                gSounds['build']:play()
            end
            return
        end
    end
end

function EnemyAI:buildNetherTurret(grid)
    local candidateSpots = {
        {17, 4}, {17, 8}, {15, 6}, {16, 6}
    }

    for _, spot in ipairs(candidateSpots) do
        local x, y = spot[1], spot[2]
        local tile = grid:getTile(x, y, 'nether')
        if tile and tile.type == Tile.VOID_FLOOR then
            self.gold = self.gold - 25
            self.stone = self.stone - 10
            grid:buildTile(x, y, Tile.TURRET_ENEMY, 'nether')
            self.playState:addFloatingText((x - 0.5) * 32, (y - 0.5) * 32, "[GGUF AI] Void Turret!", {1, 0.3, 0.5}, 'nether')
            if self.playState.hero.dimension == 'nether' then
                gSounds['build']:stop()
                gSounds['build']:play()
            end
            return
        end
    end
end

function EnemyAI:buildNetherHealingChamber(grid)
    local spots = {
        {18, 6}, {19, 5}, {19, 7}
    }

    for _, spot in ipairs(spots) do
        local x, y = spot[1], spot[2]
        local tile = grid:getTile(x, y, 'nether')
        if tile and tile.type == Tile.VOID_FLOOR then
            self.gold = self.gold - 50
            self.stone = self.stone - 60
            self.voidEssence = self.voidEssence - 20
            grid:buildTile(x, y, Tile.HEALING_CHAMBER, 'nether')
            self.playState:addFloatingText((x - 0.5) * 32, (y - 0.5) * 32, "[GGUF AI] Sanctuary!", {0.2, 1.0, 0.5}, 'nether')
            if self.playState.hero.dimension == 'nether' then
                gSounds['build']:stop()
                gSounds['build']:play()
            end
            return
        end
    end
end

function EnemyAI:rebuildNetherAnchor(grid)
    local tile = grid:getTile(19, 6, 'nether')
    if tile and (tile.type == Tile.VOID_FLOOR or tile.health <= 0) then
        self.voidEssence = self.voidEssence - 30
        self.gold = self.gold - 20
        tile:setType(Tile.NETHER_ANCHOR_ENEMY)
        self.playState:addFloatingText((19 - 0.5) * 32, (6 - 0.5) * 32, "[GGUF AI] Anchor Rebuilt!", {1, 0.3, 0.8}, 'nether')
        if self.playState.hero.dimension == 'nether' then
            gSounds['build']:stop()
            gSounds['build']:play()
        end
    end
end

return EnemyAI
