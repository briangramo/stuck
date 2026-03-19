local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StaticAssetRegistry = require(ReplicatedStorage.Shared.Config.StaticAssetRegistry)

local SpectateService = {
    cycleRemote = nil,
    stateRemote = nil,
}

local function targetPosition(target)
    if not target or not target.instance then
        return nil
    end

    local focus = target.instance:FindFirstChild("SpectateFocus")
    if focus and focus:IsA("BasePart") then
        return focus.Position
    end

    if target.kind == "Player" then
        local root = target.instance:FindFirstChild("HumanoidRootPart")
        if root then
            return root.Position
        end
    end

    return target.instance:GetPivot().Position
end

local function buildTargets(ctx, player)
    local targets = {}
    local ownMonument = ctx.Services.StuckService.GetOrCreateMonument(ctx, player.UserId)
    local ownRecord = ctx.Services.StuckService.GetRecord(player.UserId)

    if ownMonument and ownRecord then
        table.insert(targets, {
            kind = "Monument",
            key = string.format("monument:%d", player.UserId),
            name = ownRecord.displayName,
            instance = ownMonument,
        })
    end

    local living = {}
    for _, state in pairs(ctx.State.players) do
        if state.player ~= player and not state.isStuck and state.character and state.humanoid and state.humanoid.Health > 0 then
            table.insert(living, {
                kind = "Player",
                key = string.format("player:%d", state.player.UserId),
                name = state.player.DisplayName,
                instance = state.character,
            })
        end
    end

    table.sort(living, function(left, right)
        return left.name < right.name
    end)

    for _, target in ipairs(living) do
        table.insert(targets, target)
    end

    local monuments = {}
    for userId, entry in pairs(ctx.State.monuments) do
        if userId ~= player.UserId and entry.model and entry.record then
            table.insert(monuments, {
                kind = "Monument",
                key = string.format("monument:%d", userId),
                name = entry.record.displayName,
                instance = entry.model,
            })
        end
    end

    table.sort(monuments, function(left, right)
        return left.name < right.name
    end)

    for _, target in ipairs(monuments) do
        table.insert(targets, target)
    end

    return targets
end

function SpectateService.PushState(ctx, player)
    local state = ctx.State.players[player.UserId]
    if not state or not state.isStuck then
        return
    end

    local targets = buildTargets(ctx, player)
    if #targets == 0 then
        SpectateService.stateRemote:FireClient(player, {
            isStuck = true,
            distance = state.stuckDistance or 0,
            targetName = "NO TARGETS",
            targetKind = "None",
            targetInstance = nil,
        })
        return
    end

    local currentIndex = state.spectateIndex or 1
    if currentIndex < 1 or currentIndex > #targets then
        currentIndex = 1
    end

    local target = targets[currentIndex]
    state.spectateIndex = currentIndex
    state.focusPosition = targetPosition(target)

    SpectateService.stateRemote:FireClient(player, {
        isStuck = true,
        distance = state.stuckDistance or state.farthestDistance or 0,
        targetName = target.name,
        targetKind = target.kind,
        targetInstance = target.instance,
    })
end

function SpectateService.Activate(player)
    local ctx = SpectateService.ctx
    local state = ctx.State.players[player.UserId]
    if not state then
        return
    end

    state.spectateIndex = 1
    SpectateService.PushState(ctx, player)
end

function SpectateService.Cycle(player, step)
    local ctx = SpectateService.ctx
    local state = ctx.State.players[player.UserId]
    if not state or not state.isStuck then
        return
    end

    local targets = buildTargets(ctx, player)
    if #targets == 0 then
        return
    end

    local nextIndex = (state.spectateIndex or 1) + step
    if nextIndex < 1 then
        nextIndex = #targets
    elseif nextIndex > #targets then
        nextIndex = 1
    end

    state.spectateIndex = nextIndex
    SpectateService.PushState(ctx, player)
end

function SpectateService.Init(ctx)
    SpectateService.ctx = ctx
    SpectateService.cycleRemote = StaticAssetRegistry.GetInstance("network", "SpectateCycleRequest")
    SpectateService.stateRemote = StaticAssetRegistry.GetInstance("network", "SpectateStateChanged")

    SpectateService.cycleRemote.OnServerEvent:Connect(function(player, step)
        if step == -1 or step == 1 then
            SpectateService.Cycle(player, step)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(ctx.Config.SPECTATE_REFRESH_RATE)
            for _, player in ipairs(Players:GetPlayers()) do
                local state = ctx.State.players[player.UserId]
                if state and state.isStuck then
                    SpectateService.PushState(ctx, player)
                end
            end
        end
    end)

    ctx.Services.SpectateService = SpectateService
end

return SpectateService
