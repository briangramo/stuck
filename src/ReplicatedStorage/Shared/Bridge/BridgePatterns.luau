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

local function addWeightedPlatforms(definition, weights, gapSize, offsets, width)
    local segmentLength = GameConfig.BRIDGE_SEGMENT_LENGTH
    local count = #weights

    if count == 1 then
        table.insert(definition.platforms, makePlatform(segmentLength * 0.5, offsets[1] or 0, segmentLength, width))
        return
    end

    local minimumPlatformLength = 6
    local maxGapSize = (segmentLength - (count * minimumPlatformLength)) / (count - 1)
    local resolvedGapSize = math.max(0, math.min(gapSize, maxGapSize))
    local totalPlatformLength = segmentLength - (resolvedGapSize * (count - 1))
    local totalWeight = 0

    for _, weight in ipairs(weights) do
        totalWeight += weight
    end

    local cursor = 0
    for index, weight in ipairs(weights) do
        local length = index == count and (segmentLength - cursor) or (totalPlatformLength * (weight / totalWeight))
        table.insert(
            definition.platforms,
            makePlatform(cursor + (length * 0.5), offsets[index] or 0, length, width)
        )
        cursor += length
        if index < count then
            cursor += resolvedGapSize
        end
    end
end

local function dangerTier(segmentIndex)
    local distance = segmentIndex * GameConfig.BRIDGE_SEGMENT_LENGTH
    return math.floor(distance / GameConfig.MILESTONE_INTERVAL)
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
    local patternIndex = (hash(segmentIndex + 11) % 5) + 1
    local sign = (hash(segmentIndex + 29) % 2 == 0) and 1 or -1
    local tier = dangerTier(segmentIndex)
    local narrowGap = 2 + (tier * 0.35)
    local mediumGap = 3 + (tier * 0.55)
    local steppingGap = 1.6 + (tier * 0.35)

    local definition = {
        segmentIndex = segmentIndex,
        baseX = GameConfig.BRIDGE_START_X + (segmentIndex * GameConfig.BRIDGE_SEGMENT_LENGTH),
        platforms = {},
        obstacles = {},
    }

    if patternIndex == 1 then
        if tier == 0 then
            addWeightedPlatforms(definition, { 1 }, 0, { 0 }, GameConfig.BRIDGE_WIDTH)
        else
            addWeightedPlatforms(definition, { 0.52, 0.48 }, narrowGap, { 0, 0 }, GameConfig.BRIDGE_WIDTH)
        end
    elseif patternIndex == 2 then
        addWeightedPlatforms(definition, { 1, 1, 1 }, mediumGap, { 0, 0, 0 }, GameConfig.BRIDGE_WIDTH)
    elseif patternIndex == 3 then
        addWeightedPlatforms(
            definition,
            { 1, 1, 1 },
            mediumGap,
            { 0, sign * (6 + math.min(tier * 0.4, 4)), 0 },
            GameConfig.BRIDGE_WIDTH
        )
    elseif patternIndex == 4 then
        if tier == 0 then
            addWeightedPlatforms(definition, { 1 }, 0, { 0 }, GameConfig.BRIDGE_WIDTH)
            table.insert(definition.obstacles, makeObstacle(16, 0, 4, 2, GameConfig.BRIDGE_WIDTH))
            table.insert(definition.obstacles, makeObstacle(32, 0, 4, 2, GameConfig.BRIDGE_WIDTH))
        else
            addWeightedPlatforms(definition, { 0.5, 0.5 }, narrowGap, { 0, 0 }, GameConfig.BRIDGE_WIDTH)
            local first = definition.platforms[1]
            local last = definition.platforms[#definition.platforms]
            table.insert(definition.obstacles, makeObstacle(first.position.X, first.position.Z, 4, 2, GameConfig.BRIDGE_WIDTH))
            table.insert(definition.obstacles, makeObstacle(last.position.X, last.position.Z, 4, 2, GameConfig.BRIDGE_WIDTH))
        end
    else
        local sway = 4 + math.min(tier * 0.5, 5)
        addWeightedPlatforms(
            definition,
            { 1, 1, 1, 1, 1 },
            steppingGap,
            { 0, sign * sway, sign * (sway * 1.5), sign * sway, 0 },
            10
        )
    end

    return definition
end

return BridgePatterns
