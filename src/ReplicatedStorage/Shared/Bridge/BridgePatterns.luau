local GameConfig = require(script.Parent.Parent.Config.GameConfig)

local BridgePatterns = {}

local function hash(value)
    return (value * 97 + GameConfig.WORLD_SEED * 13) % 2147483647
end

local function makePlatform(relativeCenterX, relativeCenterZ, length, width)
    return {
        position = Vector3.new(relativeCenterX, GameConfig.BRIDGE_PART_CENTER_Y, relativeCenterZ),
        size = Vector3.new(length, GameConfig.BRIDGE_PART_HEIGHT, width),
    }
end

local function makeObstacle(relativeCenterX, relativeCenterZ, height, length, width)
    return {
        position = Vector3.new(
            relativeCenterX,
            GameConfig.BRIDGE_PART_CENTER_Y + (height * 0.5) + (GameConfig.BRIDGE_PART_HEIGHT * 0.5),
            relativeCenterZ
        ),
        size = Vector3.new(length, height, width),
    }
end

function BridgePatterns.GetSegmentIndexFromX(worldX)
    local relativeX = math.max(0, worldX - GameConfig.BRIDGE_START_X)
    return math.floor(relativeX / GameConfig.BRIDGE_SEGMENT_LENGTH)
end

function BridgePatterns.GetDistanceFromPosition(position)
    local relativeX = position.X - GameConfig.BRIDGE_START_X
    if relativeX < 0 then
        return 0
    end

    return math.floor(relativeX) + 1
end

function BridgePatterns.GetSegmentDefinition(segmentIndex)
    local segmentLength = GameConfig.BRIDGE_SEGMENT_LENGTH
    local patternIndex = (hash(segmentIndex + 11) % 5) + 1
    local sign = (hash(segmentIndex + 29) % 2 == 0) and 1 or -1

    local definition = {
        segmentIndex = segmentIndex,
        baseX = GameConfig.BRIDGE_START_X + (segmentIndex * segmentLength),
        platforms = {},
        obstacles = {},
    }

    if patternIndex == 1 then
        table.insert(definition.platforms, makePlatform(24, 0, 48, GameConfig.BRIDGE_WIDTH))
    elseif patternIndex == 2 then
        table.insert(definition.platforms, makePlatform(7, 0, 14, GameConfig.BRIDGE_WIDTH))
        table.insert(definition.platforms, makePlatform(24, 0, 14, GameConfig.BRIDGE_WIDTH))
        table.insert(definition.platforms, makePlatform(41, 0, 14, GameConfig.BRIDGE_WIDTH))
    elseif patternIndex == 3 then
        table.insert(definition.platforms, makePlatform(7.5, 0, 15, GameConfig.BRIDGE_WIDTH))
        table.insert(definition.platforms, makePlatform(23.5, sign * 6, 15, GameConfig.BRIDGE_WIDTH))
        table.insert(definition.platforms, makePlatform(40, 0, 16, GameConfig.BRIDGE_WIDTH))
    elseif patternIndex == 4 then
        table.insert(definition.platforms, makePlatform(24, 0, 48, GameConfig.BRIDGE_WIDTH))
        table.insert(definition.obstacles, makeObstacle(16, 0, 4, 2, GameConfig.BRIDGE_WIDTH))
        table.insert(definition.obstacles, makeObstacle(32, 0, 4, 2, GameConfig.BRIDGE_WIDTH))
    else
        local offsets = { 0, sign * 4, sign * 8, sign * 4, 0 }
        for index, offset in ipairs(offsets) do
            table.insert(definition.platforms, makePlatform(4 + ((index - 1) * 10), offset, 8, 10))
        end
    end

    return definition
end

return BridgePatterns

