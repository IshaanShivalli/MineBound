local Tile = require 'src.world.Tile'

Grid = Class{}

function Grid:init(cols, rows, tileSize)
    self.cols = cols
    self.rows = rows
    self.tileSize = tileSize

    -- Store dual-layer dimensions
    self.dimensions = {
        ['overworld'] = {},
        ['nether'] = {}
    }

    for y = 1, rows do
        self.dimensions['overworld'][y] = {}
        self.dimensions['nether'][y] = {}
        for x = 1, cols do
            self.dimensions['overworld'][y][x] = Tile(x, y, Tile.EMPTY, 'overworld')
            self.dimensions['nether'][y][x] = Tile(x, y, Tile.VOID_FLOOR, 'nether')
        end
    end

    self:generateMaps()
end

function Grid:generateMaps()
    -- === 1. OVERWORLD FIXED STRUCTURES ===
    -- Fixed Rift Portals & Turrets
    local overworldStructures = {
        {4, 6, Tile.RIFT_PORTAL},
        {17, 6, Tile.RIFT_PORTAL},
        {10, 4, Tile.RIFT_PORTAL},
        {11, 8, Tile.RIFT_PORTAL},
        {4, 4, Tile.TURRET_PLAYER},
        {4, 8, Tile.TURRET_PLAYER},
        {8, 4, Tile.TURRET_PLAYER},
        {8, 8, Tile.TURRET_PLAYER},
        -- Enemy turrets are spawned after a grace period by PlayState
    }

    for _, pos in ipairs(overworldStructures) do
        local x, y, t = pos[1], pos[2], pos[3]
        if self:isInBounds(x, y) then
            self.dimensions['overworld'][y][x]:setType(t)
        end
    end

    -- === 2. NETHER FIXED STRUCTURES ===
    local netherStructures = {
        {4, 6, Tile.RIFT_PORTAL},
        {17, 6, Tile.RIFT_PORTAL},
        {10, 4, Tile.RIFT_PORTAL},
        {11, 8, Tile.RIFT_PORTAL},
        {2, 6, Tile.NETHER_ANCHOR_PLAYER},
        {19, 6, Tile.NETHER_ANCHOR_ENEMY},
    }

    for _, pos in ipairs(netherStructures) do
        local x, y, t = pos[1], pos[2], pos[3]
        if self:isInBounds(x, y) then
            self.dimensions['nether'][y][x]:setType(t)
        end
    end

    -- === 3. RANDOMIZED RESOURCE GENERATION ACROSS BOTH WORLDS ===
    self:populateRandomResources()
end

function Grid:populateRandomResources(heroGridX, heroGridY)
    heroGridX = heroGridX or 3
    heroGridY = heroGridY or 5

    -- 1. OVERWORLD RANDOM RESOURCES: Gold Ores, Stone/Crystal Deposits, & Natural Walls
    -- Spawn 18-24 random resource clusters across empty tiles
    local targetOverworldNodes = math.random(18, 24)
    local placed = 0
    local attempts = 0

    while placed < targetOverworldNodes and attempts < 300 do
        attempts = attempts + 1
        local rx = math.random(2, self.cols - 1)
        local ry = math.random(2, self.rows - 1)

        -- Avoid player spawn area (col 2-4, row 4-6) and enemy nexus zone (col 18-19, row 4-6)
        local isPlayerZone = (rx >= heroGridX - 1 and rx <= heroGridX + 1 and ry >= heroGridY - 1 and ry <= heroGridY + 1)
        local isNexusZone = (rx <= 2 and ry >= 4 and ry <= 6) or (rx >= self.cols - 1 and ry >= 4 and ry <= 6)

        if not isPlayerZone and not isNexusZone then
            local tile = self.dimensions['overworld'][ry][rx]
            if tile and tile.type == Tile.EMPTY then
                local roll = math.random()
                if roll < 0.45 then
                    tile:setType(Tile.GOLD)
                elseif roll < 0.75 then
                    tile:setType(Tile.CRYSTAL)
                else
                    tile:setType(Tile.WALL)
                end
                placed = placed + 1
            end
        end
    end

    -- 2. NETHER REALM RANDOM RESOURCES: Soul Crystals / Gems & Natural Obsidian Pillars
    local targetNetherNodes = math.random(16, 22)
    placed = 0
    attempts = 0

    while placed < targetNetherNodes and attempts < 300 do
        attempts = attempts + 1
        local rx = math.random(2, self.cols - 1)
        local ry = math.random(2, self.rows - 1)

        local isPlayerZone = (rx >= heroGridX - 1 and rx <= heroGridX + 1 and ry >= heroGridY - 1 and ry <= heroGridY + 1)
        local isAnchorZone = (rx <= 2 and ry >= 5 and ry <= 7) or (rx >= self.cols - 1 and ry >= 5 and ry <= 7)

        if not isPlayerZone and not isAnchorZone then
            local tile = self.dimensions['nether'][ry][rx]
            if tile and tile.type == Tile.VOID_FLOOR then
                local roll = math.random()
                if roll < 0.60 then
                    tile:setType(Tile.VOID_CRYSTAL)
                else
                    tile:setType(Tile.VOID_WALL)
                end
                placed = placed + 1
            end
        end
    end
end

function Grid:isInBounds(gridX, gridY)
    return gridX >= 1 and gridX <= self.cols and gridY >= 1 and gridY <= self.rows
end

function Grid:getTile(gridX, gridY, dimension)
    dimension = dimension or 'overworld'
    if not self:isInBounds(gridX, gridY) then
        return nil
    end
    return self.dimensions[dimension][gridY][gridX]
end

function Grid:worldToGrid(worldX, worldY)
    local gridX = math.floor(worldX / self.tileSize) + 1
    local gridY = math.floor(worldY / self.tileSize) + 1
    return gridX, gridY
end

function Grid:gridToWorld(gridX, gridY)
    return (gridX - 1) * self.tileSize, (gridY - 1) * self.tileSize
end

function Grid:mineTile(gridX, gridY, damage, dimension)
    dimension = dimension or 'overworld'
    local tile = self:getTile(gridX, gridY, dimension)
    if not tile or tile.type == Tile.EMPTY or tile.type == Tile.VOID_FLOOR or tile.type == Tile.RIFT_PORTAL then
        return nil, 0
    end

    local dropType = nil
    local dropAmount = 0

    if tile.type == Tile.GOLD then
        dropType = 'gold'
        dropAmount = 25
    elseif tile.type == Tile.CRYSTAL then
        dropType = 'stone'
        dropAmount = 35
    elseif tile.type == Tile.VOID_CRYSTAL then
        dropType = 'void_essence'
        dropAmount = 30
    elseif tile.type == Tile.WALL or tile.type == Tile.VOID_WALL then
        dropType = 'stone'
        dropAmount = 15
    end

    local destroyed = tile:takeDamage(damage or 25)
    if destroyed then
        local emptyType = (dimension == 'nether') and Tile.VOID_FLOOR or Tile.EMPTY
        tile:setType(emptyType)
        return dropType, dropAmount
    end
    return nil, 0
end

function Grid:buildTile(gridX, gridY, tileType, dimension)
    dimension = dimension or 'overworld'
    local tile = self:getTile(gridX, gridY, dimension)
    local emptyType = (dimension == 'nether') and Tile.VOID_FLOOR or Tile.EMPTY
    if not tile or tile.type ~= emptyType then return false end

    tile:setType(tileType)
    return true
end

function Grid:getAnchor(dimension, owner)
    local targetType = (owner == 'player') and Tile.NETHER_ANCHOR_PLAYER or Tile.NETHER_ANCHOR_ENEMY
    for y = 1, self.rows do
        for x = 1, self.cols do
            local tile = self.dimensions['nether'][y][x]
            if tile.type == targetType and tile.health > 0 then
                return tile
            end
        end
    end
    return nil
end

function Grid:update(dt, playState)
    for y = 1, self.rows do
        for x = 1, self.cols do
            self.dimensions['overworld'][y][x]:update(dt, playState)
            self.dimensions['nether'][y][x]:update(dt, playState)
        end
    end
end

function Grid:render(dimension)
    dimension = dimension or 'overworld'
    local dimGrid = self.dimensions[dimension]
    for y = 1, self.rows do
        for x = 1, self.cols do
            local tile = dimGrid[y][x]
            local pixelX, pixelY = self:gridToWorld(x, y)
            tile:render(pixelX, pixelY, self.tileSize)
        end
    end
end

return Grid