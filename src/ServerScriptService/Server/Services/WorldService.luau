local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)

local WorldService = {}

local function createPart(name, parent, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Parent = parent
    return part
end

local function addSlimeParticles(part)
    local attachment = Instance.new("Attachment")
    attachment.Parent = part

    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 2
    emitter.Lifetime = NumberRange.new(1.5, 2.5)
    emitter.Speed = NumberRange.new(0.5, 1.2)
    emitter.SpreadAngle = Vector2.new(12, 12)
    emitter.LightEmission = 0.8
    emitter.Color = ColorSequence.new(Color3.fromRGB(170, 255, 110), Color3.fromRGB(75, 230, 65))
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 1.4),
    })
    emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
    emitter.Parent = attachment
end

local function createBoardRows(surfaceGui)
    local header = Instance.new("TextLabel")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, -24, 0, 34)
    header.Position = UDim2.fromOffset(12, 10)
    header.Font = Enum.Font.GothamBlack
    header.Text = "RANK | PLAYERNAME | DISTANCE"
    header.TextColor3 = Color3.fromRGB(232, 255, 204)
    header.TextScaled = true
    header.Parent = surfaceGui

    local rows = {}
    for index = 1, 10 do
        local row = Instance.new("TextLabel")
        row.Name = string.format("Row%d", index)
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, -24, 0, 24)
        row.Position = UDim2.fromOffset(12, 42 + ((index - 1) * 24))
        row.Font = Enum.Font.GothamBold
        row.Text = string.format("%d | --- | 0", index)
        row.TextColor3 = Color3.fromRGB(255, 255, 255)
        row.TextScaled = true
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Parent = surfaceGui
        rows[index] = row
    end

    return rows
end

function WorldService.Init(ctx)
    local existingRoot = Workspace:FindFirstChild("StuckForeverWorld")
    if existingRoot then
        existingRoot:Destroy()
    end

    local existingAtmosphere = Lighting:FindFirstChild("StuckForeverAtmosphere")
    if existingAtmosphere then
        existingAtmosphere:Destroy()
    end

    local root = Instance.new("Folder")
    root.Name = "StuckForeverWorld"
    root.Parent = Workspace

    local lobbyFolder = Instance.new("Folder")
    lobbyFolder.Name = "Lobby"
    lobbyFolder.Parent = root

    local bridgeFolder = Instance.new("Folder")
    bridgeFolder.Name = "BridgeSegments"
    bridgeFolder.Parent = root

    local monumentFolder = Instance.new("Folder")
    monumentFolder.Name = "Monuments"
    monumentFolder.Parent = root

    local lobbyCenterY = GameConfig.LOBBY_CENTER_Y
    local lobby = createPart(
        "LobbyGround",
        lobbyFolder,
        Vector3.new(GameConfig.LOBBY_SIZE, GameConfig.LOBBY_THICKNESS, GameConfig.LOBBY_SIZE),
        CFrame.new(0, lobbyCenterY, 0),
        Color3.fromRGB(84, 145, 63),
        Enum.Material.Grass
    )
    lobby.CastShadow = false

    createPart(
        "BridgeStartStrip",
        lobbyFolder,
        Vector3.new(8, 0.3, GameConfig.BRIDGE_WIDTH + 6),
        CFrame.new(GameConfig.BRIDGE_START_X - 4, 4.2, 0),
        Color3.fromRGB(255, 242, 104),
        Enum.Material.Neon
    )

    local slimeColor = Color3.fromRGB(76, 214, 59)
    local north = createPart(
        "NorthSlime",
        lobbyFolder,
        Vector3.new(GameConfig.LOBBY_SLIME_EXTENT, GameConfig.SLIME_HEIGHT, 320),
        CFrame.new(0, GameConfig.SLIME_CENTER_Y, -260),
        slimeColor,
        Enum.Material.Neon
    )
    local south = createPart(
        "SouthSlime",
        lobbyFolder,
        Vector3.new(GameConfig.LOBBY_SLIME_EXTENT, GameConfig.SLIME_HEIGHT, 320),
        CFrame.new(0, GameConfig.SLIME_CENTER_Y, 260),
        slimeColor,
        Enum.Material.Neon
    )
    local west = createPart(
        "WestSlime",
        lobbyFolder,
        Vector3.new(320, GameConfig.SLIME_HEIGHT, GameConfig.LOBBY_SLIME_EXTENT),
        CFrame.new(-260, GameConfig.SLIME_CENTER_Y, 0),
        slimeColor,
        Enum.Material.Neon
    )
    local east = createPart(
        "EastSlime",
        lobbyFolder,
        Vector3.new(320, GameConfig.SLIME_HEIGHT, GameConfig.LOBBY_SLIME_EXTENT),
        CFrame.new(260, GameConfig.SLIME_CENTER_Y, 0),
        slimeColor,
        Enum.Material.Neon
    )
    north.Transparency = 0.2
    south.Transparency = 0.2
    west.Transparency = 0.2
    east.Transparency = 0.2
    addSlimeParticles(north)
    addSlimeParticles(south)

    local boardModel = Instance.new("Model")
    boardModel.Name = "LeaderboardBoard"
    boardModel.Parent = lobbyFolder

    local post = createPart(
        "Post",
        boardModel,
        Vector3.new(3, 18, 3),
        CFrame.new(-68, 9, -72),
        Color3.fromRGB(98, 72, 46),
        Enum.Material.Wood
    )
    local panel = createPart(
        "Panel",
        boardModel,
        Vector3.new(30, 22, 2),
        CFrame.lookAt(Vector3.new(-68, 17, -72), Vector3.new(0, 17, 0)),
        Color3.fromRGB(24, 33, 28),
        Enum.Material.Slate
    )
    boardModel.PrimaryPart = post

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "LeaderboardSurfaceGui"
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.CanvasSize = Vector2.new(900, 500)
    surfaceGui.Parent = panel

    local rows = createBoardRows(surfaceGui)

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "StuckForeverAtmosphere"
    atmosphere.Density = 0.3
    atmosphere.Haze = 1.5
    atmosphere.Color = Color3.fromRGB(178, 247, 156)
    atmosphere.Decay = Color3.fromRGB(77, 153, 68)
    atmosphere.Parent = Lighting

    ctx.World = {
        Root = root,
        Lobby = lobbyFolder,
        BridgeSegments = bridgeFolder,
        Monuments = monumentFolder,
        LeaderboardRows = rows,
        SpawnPosition = GameConfig.SPAWN_POSITION,
    }

    ctx.Services.WorldService = WorldService
end

return WorldService

