local Players = game:GetService("Players")

local PlayerService = {}

local function onCharacterAdded(ctx, player, character)
    local state = ctx.State.players[player.UserId]
    if not state or state.isStuck then
        character:Destroy()
        return
    end

    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root then
        return
    end

    state.character = character
    state.humanoid = humanoid
    state.root = root
    state.lastRootPosition = root.Position
    state.focusPosition = root.Position

    character:PivotTo(CFrame.new(ctx.World.SpawnPosition))

    humanoid.Died:Connect(function()
        ctx.Services.StuckService.MarkPlayerStuck(ctx, player)
    end)
end

local function onCharacterRemoving(ctx, player)
    local state = ctx.State.players[player.UserId]
    if not state then
        return
    end

    state.character = nil
    state.root = nil
    state.humanoid = nil
end

local function onPlayerAdded(ctx, player)
    local state = {
        player = player,
        isStuck = false,
        processingStuck = false,
        currentDistance = 0,
        farthestDistance = 0,
        stuckDistance = 0,
        lastCelebratedMilestone = 0,
        focusPosition = ctx.World.SpawnPosition,
    }
    ctx.State.players[player.UserId] = state

    local record, loadError = ctx.Services.StuckService.LoadPlayerRecord(player)
    if loadError then
        player:Kick("Could not verify Stuck Forever data.")
        return
    end

    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(ctx, player, character)
    end)
    player.CharacterRemoving:Connect(function()
        onCharacterRemoving(ctx, player)
    end)

    if record and record.isStuck then
        state.isStuck = true
        state.currentDistance = record.distance
        state.farthestDistance = record.distance
        state.stuckDistance = record.distance
        state.lastCelebratedMilestone = math.floor(record.distance / ctx.Config.MILESTONE_INTERVAL)
        state.focusPosition = Vector3.new(record.position.x, record.position.y, record.position.z)
        ctx.State.monuments[player.UserId] = {
            record = record,
            model = nil,
        }
        ctx.Services.StuckService.GetOrCreateMonument(ctx, player.UserId)
        task.defer(function()
            ctx.Services.SpectateService.Activate(player)
        end)
    else
        player:LoadCharacter()
    end
end

local function onPlayerRemoving(ctx, player)
    ctx.State.players[player.UserId] = nil
end

function PlayerService.Init(ctx)
    Players.CharacterAutoLoads = false

    Players.PlayerAdded:Connect(function(player)
        onPlayerAdded(ctx, player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        onPlayerRemoving(ctx, player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            onPlayerAdded(ctx, player)
        end)
    end

    ctx.Services.PlayerService = PlayerService
end

return PlayerService
