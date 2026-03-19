local Players = game:GetService("Players")

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)

local MonumentFactory = {}

local function addBillboard(parent, displayName, distance)
    local adornee = parent:FindFirstChild("Head") or parent:FindFirstChild("HumanoidRootPart") or parent.PrimaryPart
    if not adornee then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MonumentBillboard"
    billboard.Size = UDim2.fromOffset(220, 64)
    billboard.StudsOffset = Vector3.new(0, 6, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = adornee
    billboard.Parent = parent

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = displayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Position = UDim2.fromScale(0, 0.5)
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Font = Enum.Font.GothamBlack
    distanceLabel.Text = string.format("DISTANCE %d STUDS", distance)
    distanceLabel.TextColor3 = Color3.fromRGB(179, 255, 170)
    distanceLabel.TextScaled = true
    distanceLabel.Parent = billboard
end

local function stripScripts(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BaseScript") or descendant:IsA("Animator") then
            descendant:Destroy()
        end
    end
end

local function anchorModel(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = true
        elseif descendant:IsA("Humanoid") then
            descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            descendant.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            descendant.BreakJointsOnDeath = false
        end
    end
end

local function ensureFocusPart(model)
    local pivot = model:GetPivot().Position
    local focus = Instance.new("Part")
    focus.Name = "SpectateFocus"
    focus.Size = Vector3.new(1, 1, 1)
    focus.Transparency = 1
    focus.Anchored = true
    focus.CanCollide = false
    focus.CanTouch = false
    focus.CanQuery = false
    focus.Position = pivot + Vector3.new(0, 4, 0)
    focus.Parent = model
    return focus
end

local function finalizeModel(model, record, parent)
    model.Name = string.format("Monument_%d", record.userId)
    stripScripts(model)
    anchorModel(model)
    local focus = ensureFocusPart(model)
    addBillboard(model, record.displayName, record.distance)
    model:SetAttribute("UserId", record.userId)
    model:SetAttribute("Distance", record.distance)
    model:SetAttribute("ChunkIndex", record.chunkIndex)
    model.Parent = parent
    if not model.PrimaryPart then
        model.PrimaryPart = focus
    end
    return model
end

local function createFallbackModel(record)
    local model = Instance.new("Model")

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Color = Color3.fromRGB(123, 129, 137)
    root.Material = Enum.Material.Slate
    root.Parent = model

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = Color3.fromRGB(95, 102, 110)
    torso.Material = Enum.Material.Slate
    torso.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Color = Color3.fromRGB(164, 170, 178)
    head.Material = Enum.Material.Slate
    head.Parent = model

    model.PrimaryPart = root
    model:PivotTo(
        CFrame.new(record.position.x, math.max(record.position.y, GameConfig.SLIME_CENTER_Y + 2), record.position.z)
            * CFrame.Angles(math.rad(75), math.rad(20), 0)
    )

    torso.CFrame = root.CFrame * CFrame.new(0, 1.5, 0)
    head.CFrame = torso.CFrame * CFrame.new(0, 1.75, 0)

    return model
end

function MonumentFactory.CreateFromCharacter(character, record, parent)
    local clone = character:Clone()
    clone:PivotTo(
        CFrame.new(record.position.x, record.position.y, record.position.z)
            * CFrame.Angles(math.rad(75), math.rad(20), 0)
    )
    return finalizeModel(clone, record, parent)
end

function MonumentFactory.CreateFromRecord(record, parent)
    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromUserId(record.userId)
    end)

    if not ok or not model then
        model = createFallbackModel(record)
    else
        model:PivotTo(
            CFrame.new(record.position.x, math.max(record.position.y, GameConfig.SLIME_CENTER_Y + 2), record.position.z)
                * CFrame.Angles(math.rad(75), math.rad(20), 0)
        )
    end

    return finalizeModel(model, record, parent)
end

return MonumentFactory
