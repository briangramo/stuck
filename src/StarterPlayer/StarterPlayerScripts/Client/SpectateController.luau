local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local StaticAssetRegistry = require(ReplicatedStorage.Shared.Config.StaticAssetRegistry)

local SpectateController = {
    ui = nil,
    titleLabel = nil,
    distanceLabel = nil,
    targetLabel = nil,
    currentTargetInstance = nil,
    currentTargetKind = nil,
}

local function styleButton(button)
    button.BackgroundColor3 = Color3.fromRGB(32, 46, 28)
    button.TextColor3 = Color3.fromRGB(229, 255, 220)
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.AutoButtonColor = true
end

local function buildUi(playerGui)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StuckForeverSpectate"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    local root = Instance.new("Frame")
    root.AnchorPoint = Vector2.new(0.5, 1)
    root.Position = UDim2.fromScale(0.5, 0.97)
    root.Size = UDim2.fromOffset(420, 150)
    root.BackgroundColor3 = Color3.fromRGB(14, 18, 13)
    root.BackgroundTransparency = 0.18
    root.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = root

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(112, 255, 104)
    stroke.Thickness = 2
    stroke.Parent = root

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(20, 12)
    title.Size = UDim2.new(1, -40, 0, 28)
    title.Font = Enum.Font.GothamBlack
    title.Text = "YOUR ARE STUCK FOREVER"
    title.TextColor3 = Color3.fromRGB(245, 255, 240)
    title.TextScaled = true
    title.Parent = root

    local distance = Instance.new("TextLabel")
    distance.BackgroundTransparency = 1
    distance.Position = UDim2.fromOffset(20, 42)
    distance.Size = UDim2.new(1, -40, 0, 22)
    distance.Font = Enum.Font.GothamBold
    distance.Text = "DISTANCE 0 STUDS"
    distance.TextColor3 = Color3.fromRGB(178, 255, 166)
    distance.TextScaled = true
    distance.Parent = root

    local target = Instance.new("TextLabel")
    target.BackgroundTransparency = 1
    target.Position = UDim2.fromOffset(20, 82)
    target.Size = UDim2.new(1, -40, 0, 22)
    target.Font = Enum.Font.GothamBlack
    target.Text = "---"
    target.TextColor3 = Color3.fromRGB(255, 255, 255)
    target.TextScaled = true
    target.Parent = root

    local controls = Instance.new("Frame")
    controls.BackgroundTransparency = 1
    controls.Position = UDim2.fromOffset(18, 112)
    controls.Size = UDim2.new(1, -36, 0, 28)
    controls.Parent = root

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.Parent = controls

    local prevButton = Instance.new("TextButton")
    prevButton.Size = UDim2.fromOffset(110, 28)
    prevButton.Text = "PREV"
    prevButton.Parent = controls
    styleButton(prevButton)

    local inviteButton = Instance.new("TextButton")
    inviteButton.Size = UDim2.fromOffset(110, 28)
    inviteButton.Text = "INVITE"
    inviteButton.Parent = controls
    styleButton(inviteButton)

    local nextButton = Instance.new("TextButton")
    nextButton.Size = UDim2.fromOffset(110, 28)
    nextButton.Text = "NEXT"
    nextButton.Parent = controls
    styleButton(nextButton)

    return screenGui, title, distance, target, prevButton, inviteButton, nextButton
end

local function applyCamera(instance, kind)
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    if kind == "Player" and instance then
        local humanoid = instance:FindFirstChildOfClass("Humanoid")
        if humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
            return
        end
    end

    camera.CameraType = Enum.CameraType.Scriptable

    if instance then
        local focus = instance:FindFirstChild("SpectateFocus")
        local targetPosition = if focus and focus:IsA("BasePart") then focus.Position else instance:GetPivot().Position
        camera.CFrame = CFrame.lookAt(targetPosition + Vector3.new(-16, 10, 16), targetPosition + Vector3.new(0, 2, 0))
    else
        camera.CFrame = CFrame.lookAt(Vector3.new(0, 24, -40), Vector3.new(0, 4, 0))
    end
end

function SpectateController.Init(ctx)
    local player = ctx.player
    local playerGui = player:WaitForChild("PlayerGui")
    local cycleRemote = StaticAssetRegistry.GetInstance("network", "SpectateCycleRequest")
    local stateRemote = StaticAssetRegistry.GetInstance("network", "SpectateStateChanged")

    local ui, titleLabel, distanceLabel, targetLabel, prevButton, inviteButton, nextButton = buildUi(playerGui)
    SpectateController.ui = ui
    SpectateController.titleLabel = titleLabel
    SpectateController.distanceLabel = distanceLabel
    SpectateController.targetLabel = targetLabel

    prevButton.Activated:Connect(function()
        cycleRemote:FireServer(-1)
    end)

    nextButton.Activated:Connect(function()
        cycleRemote:FireServer(1)
    end)

    inviteButton.Activated:Connect(function()
        pcall(function()
            SocialService:PromptGameInvite(player)
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not SpectateController.ui.Enabled then
            return
        end

        if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
            cycleRemote:FireServer(-1)
        elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
            cycleRemote:FireServer(1)
        end
    end)

    stateRemote.OnClientEvent:Connect(function(payload)
        SpectateController.ui.Enabled = payload.isStuck == true
        if not SpectateController.ui.Enabled then
            return
        end

        SpectateController.distanceLabel.Text = string.format("DISTANCE %d STUDS", payload.distance or 0)
        SpectateController.targetLabel.Text = payload.targetName or "---"
        SpectateController.currentTargetInstance = payload.targetInstance
        SpectateController.currentTargetKind = payload.targetKind
        applyCamera(payload.targetInstance, payload.targetKind)
    end)

    pcall(function()
        StarterGui:SetCore("ResetButtonCallback", false)
    end)
end

return SpectateController
