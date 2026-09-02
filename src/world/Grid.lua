local Tile = require 'src.world.Tile'

Grid = Class{}

function Grid:init(cols, rows, tileSize)
    self.cols = cols
    self.rows = rows
    self.tileSize = tileSize
    self.tiles = {}

    for y = 1, rows do
        self.tiles[y] = {}
        for x = 1, cols do
            self.tiles[y][x] = Tile(x, y, Tile.EMPTY)
        end
    end

    self:generateMap()
end

function Grid:generateMap()
    -- Create boundaries or obstacles
    -- Middle resource field
    local resourcePositions = {
        {8, 4, Tile.GOLD}, {9, 4, Tile.GOLD}, {8, 8, Tile.GOLD}, {9, 8, Tile.GOLD},
        {12, 4, Tile.GOLD}, {13, 4, Tile.GOLD}, {12, 8, Tile.GOLD}, {13, 8, Tile.GOLD},
        {10, 6, Tile.CRYSTAL}, {11, 6, Tile.CRYSTAL},
        {10, 2, Tile.WALL}, {11, 2, Tile.WALL},
        {10, 10, Tile.WALL}, {11, 10, Tile.WALL},
        {6, 5, Tile.WALL}, {6, 7, Tile.WALL},
        {15, 5, Tile.WALL}, {15, 7, Tile.WALL},
    }

    for _, pos in ipairs(resourcePositions) do
        local x, y, t = pos[1], pos[2], pos[3]
        if self:isInBounds(x, y) then
            self.tiles[y][x]:setType(t)
        end
    end

    -- Turrets
    self.tiles[4][4]:setType(Tile.TURRET_PLAYER)
    self.tiles[8][4]:setType(Tile.TURRET_PLAYER)

    self.tiles[4][17]:setType(Tile.TURRET_ENEMY)
    self.tiles[8][17]:setType(Tile.TURRET_ENEMY)
end

function Grid:isInBounds(gridX, gridY)
    return gridX >= 1 and gridX <= self.cols and gridY >= 1 and gridY <= self.rows
end

function Grid:getTile(gridX, gridY)
    if not self:isInBounds(gridX, gridY) then
        return nil
    end
    return self.tiles[gridY][gridX]
end

function Grid:worldToGrid(worldX, worldY)
    local gridX = math.floor(worldX / self.tileSize) + 1
    local gridY = math.floor(worldY / self.tileSize) + 1
    return gridX, gridY
end

function Grid:gridToWorld(gridX, gridY)
    return (gridX - 1) * self.tileSize, (gridY - 1) * self.tileSize
end

function Grid:mineTile(gridX, gridY, damage)
    local tile = self:getTile(gridX, gridY)
    if not tile or tile.type == Tile.EMPTY then return nil end

    local dropType = nil
    local dropAmount = 0

    if tile.type == Tile.GOLD then
        dropType = 'gold'
        dropAmount = 15
    elseif tile.type == Tile.CRYSTAL then
        dropType = 'crystal'
        dropAmount = 25
    elseif tile.type == Tile.WALL then
        dropType = 'stone'
        dropAmount = 10
    end

    local destroyed = tile:takeDamage(damage or 25)
    if destroyed then
        tile:setType(Tile.EMPTY)
        return dropType, dropAmount
    end
    return nil, 0
end

function Grid:buildTile(gridX, gridY, tileType)
    local tile = self:getTile(gridX, gridY)
    if not tile or tile.type ~= Tile.EMPTY then return false end

    tile:setType(tileType)
    return true
end

function Grid:toggleBlock(gridX, gridY)
    local tile = self:getTile(gridX, gridY)
    if not tile then return end

    if tile.type == Tile.EMPTY then
        tile:setType(Tile.WALL)
    else
        tile:setType(Tile.EMPTY)
    end
end

function Grid:update(dt, playState)
    for y = 1, self.rows do
        for x = 1, self.cols do
            self.tiles[y][x]:update(dt, playState)
        end
    end
end

function Grid:render()
    for y = 1, self.rows do
        for x = 1, self.cols do
            local tile = self.tiles[y][x]
            local pixelX, pixelY = self:gridToWorld(x, y)
            tile:render(pixelX, pixelY, self.tileSize)
        end
    end
end

return Grid