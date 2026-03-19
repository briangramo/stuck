local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local StaticAssetRegistry = require(ReplicatedStorage.Shared.Config.StaticAssetRegistry)

local MilestoneController = {
    statusLabel = nil,
    popupLabel = nil,
    celebrationSound = nil,
    animationToken = 0,
}

local UNCONFIGURED_SOUND_ID = "rbxassetid://0"

local function buildUi(playerGui)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MilestoneHud"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    local status = Instance.new("TextLabel")
    status.Name = "MilestoneStatus"
    status.AnchorPoint = Vector2.new(0.5, 0)
    status.Position = UDim2.new(0.5, 0, 0, 12)
    status.Size = UDim2.fromOffset(280, 30)
    status.BackgroundTransparency = 0.22
    status.BackgroundColor3 = Color3.fromRGB(39, 55, 36)
    status.BorderSizePixel = 0
    status.Font = Enum.Font.GothamBold
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(240, 255, 215)
    status.TextScaled = true
    status.Visible = false
    status.Parent = screenGui

    local popup = Instance.new("TextLabel")
    popup.Name = "MilestonePopup"
    popup.AnchorPoint = Vector2.new(0.5, 0)
    popup.Position = UDim2.new(0.5, 0, 0, 44)
    popup.Size = UDim2.fromOffset(220, 42)
    popup.BackgroundTransparency = 1
    popup.BackgroundColor3 = Color3.fromRGB(250, 214, 102)
    popup.BorderSizePixel = 0
    popup.Font = Enum.Font.GothamBlack
    popup.Text = ""
    popup.TextColor3 = Color3.fromRGB(35, 44, 24)
    popup.TextScaled = true
    popup.TextTransparency = 1
    popup.TextStrokeTransparency = 1
    popup.Visible = false
    popup.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = status

    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 16)
    popupCorner.Parent = popup

    return status, popup
end

local function ensureCelebrationSound()
    if MilestoneController.celebrationSound and MilestoneController.celebrationSound.Parent then
        return MilestoneController.celebrationSound
    end

    local entry = StaticAssetRegistry.GetEntry("sounds", "MilestoneCelebration")
    if entry.soundId == UNCONFIGURED_SOUND_ID then
        return nil
    end

    local template = StaticAssetRegistry.GetInstance("sounds", "MilestoneCelebration")
    local sound = template:Clone()
    sound.Name = "MilestoneCelebrationLocal"
    sound.Parent = SoundService
    MilestoneController.celebrationSound = sound
    return sound
end

local function showCelebration(distance)
    MilestoneController.animationToken += 1
    local token = MilestoneController.animationToken
    local popup = MilestoneController.popupLabel
    local status = MilestoneController.statusLabel
    if not popup or not status then
        return
    end

    status.Text = string.format("Reached %d Studs!", distance)
    status.Visible = true

    popup.Text = string.format("%d STUDS!", distance)
    popup.Visible = true
    popup.Position = UDim2.new(0.5, 0, 0, 52)
    popup.BackgroundTransparency = 1
    popup.TextTransparency = 1
    popup.TextStrokeTransparency = 1

    TweenService:Create(
        popup,
        TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(0.5, 0, 0, 44),
            BackgroundTransparency = 0.12,
            TextTransparency = 0,
            TextStrokeTransparency = 0.75,
        }
    ):Play()

    task.spawn(function()
        task.wait(1.2)
        if MilestoneController.animationToken ~= token then
            return
        end

        local fade = TweenService:Create(
            popup,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = UDim2.new(0.5, 0, 0, 34),
                BackgroundTransparency = 1,
                TextTransparency = 1,
                TextStrokeTransparency = 1,
            }
        )
        fade:Play()
        fade.Completed:Wait()
        if MilestoneController.animationToken == token then
            popup.Visible = false
        end
    end)

    local sound = ensureCelebrationSound()
    if sound then
        sound.TimePosition = 0
        sound:Play()
    end
end

function MilestoneController.Init(ctx)
    local playerGui = ctx.player:WaitForChild("PlayerGui")
    local status, popup = buildUi(playerGui)
    local remote = StaticAssetRegistry.GetInstance("network", "DistanceMilestoneReached")

    MilestoneController.statusLabel = status
    MilestoneController.popupLabel = popup

    remote.OnClientEvent:Connect(function(payload)
        if payload and payload.distance then
            showCelebration(payload.distance)
        end
    end)
end

return MilestoneController
