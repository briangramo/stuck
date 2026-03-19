local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgePatterns = require(ReplicatedStorage.Shared.Bridge.BridgePatterns)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local BridgeService = {
    loadedSegments = {},
}

local function addSlimeParticles(part)
    local attachment = Instance.new("Attachment")
    attachment.Parent = part

    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 1
    emitter.Lifetime = NumberRange.new(1.2, 2.2)
    emitter.Speed = NumberRange.new(0.3, 0.8)
    emitter.SpreadAngle = Vector2.new(6, 6)
    emitter.LightEmission = 0.7
    emitter.Color = ColorSequence.new(Color3.fromRGB(160, 255, 126), Color3.fromRGB(65, 219, 74))
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
    emitter.Parent = attachment
end

local function createSegmentPart(name, parent, position, size, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Position = position
    part.Size = size
    part.Color = color
    part.Material = material
    part.Parent = parent
    return part
end

local function createSegmentModel(ctx, segmentIndex)
    local definition = BridgePatterns.GetSegmentDefinition(segmentIndex)
    local model = Instance.new("Model")
    model.Name = string.format("Segment_%06d", segmentIndex)
    model.Parent = ctx.World.BridgeSegments

    for index, platform in ipairs(definition.platforms) do
        createSegmentPart(
            string.format("Platform_%02d", index),
            model,
            Vector3.new(definition.baseX + platform.position.X, platform.position.Y, platform.position.Z),
            platform.size,
            Color3.fromRGB(104, 109, 120),
            Enum.Material.Concrete
        )
    end

    for index, obstacle in ipairs(definition.obstacles) do
        createSegmentPart(
            string.format("Obstacle_%02d", index),
            model,
            Vector3.new(definition.baseX + obstacle.position.X, obstacle.position.Y, obstacle.position.Z),
            obstacle.size,
            Color3.fromRGB(185, 82, 64),
            Enum.Material.Metal
        )
    end

    local slime = createSegmentPart(
        "Slime",
        model,
        Vector3.new(definition.baseX + (GameConfig.BRIDGE_SEGMENT_LENGTH * 0.5), GameConfig.SLIME_CENTER_Y, 0),
        Vector3.new(GameConfig.BRIDGE_SEGMENT_LENGTH, GameConfig.SLIME_HEIGHT, 84),
        Color3.fromRGB(76, 214, 59),
        Enum.Material.Neon
    )
    slime.CanCollide = false
    slime.Transparency = 0.25
    addSlimeParticles(slime)

    BridgeService.loadedSegments[segmentIndex] = model
end

function BridgeService.SetActiveSegments(ctx, desiredSegments)
    for segmentIndex in pairs(desiredSegments) do
        if not BridgeService.loadedSegments[segmentIndex] then
            createSegmentModel(ctx, segmentIndex)
        end
    end

    for segmentIndex, model in pairs(BridgeService.loadedSegments) do
        if not desiredSegments[segmentIndex] then
            model:Destroy()
            BridgeService.loadedSegments[segmentIndex] = nil
        end
    end
end

function BridgeService.Init(ctx)
    BridgeService.loadedSegments = {}
    ctx.Services.BridgeService = BridgeService
end

return BridgeService

