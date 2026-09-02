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
    -- === 1. OVERWORLD GENERATION ===
    local overworldResources = {
        {8, 4, Tile.GOLD}, {9, 4, Tile.GOLD}, {8, 8, Tile.GOLD}, {9, 8, Tile.GOLD},
        {12, 4, Tile.GOLD}, {13, 4, Tile.GOLD}, {12, 8, Tile.GOLD}, {13, 8, Tile.GOLD},
        {10, 6, Tile.CRYSTAL}, {11, 6, Tile.CRYSTAL},
        -- Solid central walls in Overworld (blocked in Overworld, but open in Nether!)
        {10, 2, Tile.WALL}, {11, 2, Tile.WALL},
        {10, 10, Tile.WALL}, {11, 10, Tile.WALL},
        {6, 5, Tile.WALL}, {6, 7, Tile.WALL},
        {15, 5, Tile.WALL}, {15, 7, Tile.WALL},
        -- Dimensional Rift Portals in Overworld
        {4, 6, Tile.RIFT_PORTAL},
        {17, 6, Tile.RIFT_PORTAL},
        {10, 4, Tile.RIFT_PORTAL},
        {11, 8, Tile.RIFT_PORTAL},
    }

    for _, pos in ipairs(overworldResources) do
        local x, y, t = pos[1], pos[2], pos[3]
        if self:isInBounds(x, y) then
            self.dimensions['overworld'][y][x]:setType(t)
        end
    end

    -- Overworld Turrets
    self.dimensions['overworld'][4][4]:setType(Tile.TURRET_PLAYER)
    self.dimensions['overworld'][8][4]:setType(Tile.TURRET_PLAYER)
    self.dimensions['overworld'][4][17]:setType(Tile.TURRET_ENEMY)
    self.dimensions['overworld'][8][17]:setType(Tile.TURRET_ENEMY)

    -- === 2. NETHER / VOID REALM GENERATION ===
    -- Nether has inverse paths (permeable centers, dense obsidian edges, rich soul crystals)
    local netherFeatures = {
        -- Dimensional Rift Portals match Overworld locations
        {4, 6, Tile.RIFT_PORTAL},
        {17, 6, Tile.RIFT_PORTAL},
        {10, 4, Tile.RIFT_PORTAL},
        {11, 8, Tile.RIFT_PORTAL},

        -- Nether Soul Crystal fields
        {7, 3, Tile.VOID_CRYSTAL}, {7, 9, Tile.VOID_CRYSTAL},
        {14, 3, Tile.VOID_CRYSTAL}, {14, 9, Tile.VOID_CRYSTAL},
        {10, 5, Tile.VOID_CRYSTAL}, {11, 7, Tile.VOID_CRYSTAL},

        -- Obsidian labyrinth walls (blocking side lanes, keeping middle open)
        {4, 3, Tile.VOID_WALL}, {4, 9, Tile.VOID_WALL},
        {17, 3, Tile.VOID_WALL}, {17, 9, Tile.VOID_WALL},
        {8, 2, Tile.VOID_WALL}, {13, 2, Tile.VOID_WALL},
        {8, 10, Tile.VOID_WALL}, {13, 10, Tile.VOID_WALL},

        -- Nether Core Anchors (Destroying enemy anchor weakens their overworld core!)
        {2, 6, Tile.NETHER_ANCHOR_PLAYER},
        {19, 6, Tile.NETHER_ANCHOR_ENEMY},
    }

    for _, pos in ipairs(netherFeatures) do
        local x, y, t = pos[1], pos[2], pos[3]
        if self:isInBounds(x, y) then
            self.dimensions['nether'][y][x]:setType(t)
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
        dropAmount = 15
    elseif tile.type == Tile.CRYSTAL then
        dropType = 'stone'
        dropAmount = 25
    elseif tile.type == Tile.VOID_CRYSTAL then
        dropType = 'void_essence'
        dropAmount = 20
    elseif tile.type == Tile.WALL or tile.type == Tile.VOID_WALL then
        dropType = 'stone'
        dropAmount = 10
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