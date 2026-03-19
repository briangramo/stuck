local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BridgePatterns = require(ReplicatedStorage.Shared.Bridge.BridgePatterns)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MonumentFactory = require(script.Parent.Parent.Support.MonumentFactory)

local StuckService = {
    records = {},
    segmentFetchTimes = {},
    playerStore = nil,
    chunkStore = nil,
    fallbackStore = {
        players = {},
        chunks = {},
    },
}

local function copyRecord(record)
    if not record then
        return nil
    end

    return {
        isStuck = true,
        userId = record.userId,
        displayName = record.displayName,
        distance = record.distance,
        position = {
            x = record.position.x,
            y = record.position.y,
            z = record.position.z,
        },
        timestamp = record.timestamp,
        chunkIndex = record.chunkIndex,
    }
end

local function chunkKey(segmentIndex)
    return string.format("segment:%d", segmentIndex)
end

local function normalizeRecord(record)
    if not record or not record.position then
        return nil
    end

    local normalized = copyRecord(record)
    normalized.chunkIndex = normalized.chunkIndex or BridgePatterns.GetSegmentIndexFromX(normalized.position.x)
    return normalized
end

local function createEntry(ctx, record)
    local userId = record.userId
    local entry = ctx.State.monuments[userId]
    if not entry then
        entry = {
            record = record,
            model = nil,
        }
        ctx.State.monuments[userId] = entry
    else
        entry.record = record
    end

    StuckService.records[userId] = record
    return entry
end

function StuckService.LoadPlayerRecord(player)
    local key = tostring(player.UserId)

    if RunService:IsStudio() then
        return normalizeRecord(StuckService.fallbackStore.players[key])
    end

    local ok, result = pcall(function()
        return StuckService.playerStore:GetAsync(key)
    end)

    if not ok then
        return nil, result
    end

    return normalizeRecord(result)
end

function StuckService.WritePlayerRecord(record)
    local key = tostring(record.userId)
    StuckService.fallbackStore.players[key] = copyRecord(record)

    if RunService:IsStudio() then
        return true
    end

    local ok, result = pcall(function()
        StuckService.playerStore:SetAsync(key, copyRecord(record))
    end)

    if not ok then
        warn(string.format("Failed to write player record for %s: %s", key, tostring(result)))
    end

    return ok
end

function StuckService.WriteChunkRecord(record)
    local key = chunkKey(record.chunkIndex)

    local fallbackChunk = StuckService.fallbackStore.chunks[key] or { records = {} }
    fallbackChunk.records[tostring(record.userId)] = copyRecord(record)
    StuckService.fallbackStore.chunks[key] = fallbackChunk

    if RunService:IsStudio() then
        return true
    end

    local ok, result = pcall(function()
        StuckService.chunkStore:UpdateAsync(key, function(currentValue)
            local updatedValue = currentValue or { records = {} }
            updatedValue.records[tostring(record.userId)] = copyRecord(record)
            return updatedValue
        end)
    end)

    if not ok then
        warn(string.format("Failed to write chunk record %s: %s", key, tostring(result)))
    end

    return ok
end

function StuckService.GetRecord(userId)
    return StuckService.records[userId]
end

function StuckService.GetOrCreateMonument(ctx, userId)
    local entry = ctx.State.monuments[userId]
    if not entry or not entry.record then
        return nil
    end

    StuckService.records[userId] = entry.record

    if entry.model and entry.model.Parent then
        return entry.model
    end

    entry.model = MonumentFactory.CreateFromRecord(entry.record, ctx.World.Monuments)
    return entry.model
end

function StuckService.MarkPlayerStuck(ctx, player)
    local state = ctx.State.players[player.UserId]
    if not state or state.isStuck or state.processingStuck then
        return
    end

    state.processingStuck = true

    local position = state.lastRootPosition or ctx.World.SpawnPosition
    local distance = math.max(
        state.currentDistance or 0,
        state.farthestDistance or 0,
        BridgePatterns.GetDistanceFromPosition(position)
    )

    local record = normalizeRecord({
        isStuck = true,
        userId = player.UserId,
        displayName = player.DisplayName,
        distance = distance,
        position = {
            x = position.X,
            y = math.max(position.Y, GameConfig.SLIME_CENTER_Y + 2),
            z = position.Z,
        },
        timestamp = os.time(),
    })

    local entry = createEntry(ctx, record)
    if state.character then
        entry.model = MonumentFactory.CreateFromCharacter(state.character, record, ctx.World.Monuments)
    end

    StuckService.WritePlayerRecord(record)
    StuckService.WriteChunkRecord(record)

    state.isStuck = true
    state.currentDistance = distance
    state.farthestDistance = math.max(state.farthestDistance or 0, distance)
    state.stuckDistance = distance
    state.focusPosition = Vector3.new(record.position.x, record.position.y, record.position.z)
    state.character = nil
    state.root = nil
    state.humanoid = nil

    if player.Character then
        player.Character:Destroy()
    end

    state.processingStuck = false
    task.defer(function()
        ctx.Services.SpectateService.Activate(player)
    end)
end

function StuckService.LoadChunk(ctx, segmentIndex)
    local data
    local key = chunkKey(segmentIndex)

    if RunService:IsStudio() then
        data = StuckService.fallbackStore.chunks[key]
    else
        local ok, result = pcall(function()
            return StuckService.chunkStore:GetAsync(key)
        end)

        if not ok then
            warn(string.format("Failed to load chunk %s: %s", key, tostring(result)))
            return
        end

        data = result
    end

    if not data or not data.records then
        return
    end

    for _, rawRecord in pairs(data.records) do
        local record = normalizeRecord(rawRecord)
        if record then
            local existing = StuckService.records[record.userId]
            if not existing or record.timestamp >= existing.timestamp then
                local entry = createEntry(ctx, record)
                if not entry.model then
                    StuckService.GetOrCreateMonument(ctx, record.userId)
                end
            end
        end
    end
end

function StuckService.UpdateActiveSegments(ctx, desiredSegments)
    local now = os.clock()

    for segmentIndex in pairs(desiredSegments) do
        local lastFetch = StuckService.segmentFetchTimes[segmentIndex]
        if not lastFetch or (now - lastFetch) >= GameConfig.CHUNK_REFRESH_RATE then
            StuckService.segmentFetchTimes[segmentIndex] = now
            StuckService.LoadChunk(ctx, segmentIndex)
        end
    end

    for userId, entry in pairs(ctx.State.monuments) do
        local record = entry.record
        if entry.model and record and not desiredSegments[record.chunkIndex] then
            entry.model:Destroy()
            entry.model = nil
        end
    end
end

function StuckService.Init(ctx)
    StuckService.records = {}
    StuckService.segmentFetchTimes = {}
    StuckService.playerStore = DataStoreService:GetDataStore(GameConfig.DATASTORE_PLAYER)
    StuckService.chunkStore = DataStoreService:GetDataStore(GameConfig.DATASTORE_CHUNK)
    ctx.Services.StuckService = StuckService
end

return StuckService
