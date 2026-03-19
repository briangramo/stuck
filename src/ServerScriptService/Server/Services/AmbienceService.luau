local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StaticAssetRegistry = require(ReplicatedStorage.Shared.Config.StaticAssetRegistry)

local AmbienceService = {}
local UNCONFIGURED_SOUND_ID = "rbxassetid://0"
local runtimeSound = nil

local function ensureRuntimeSound()
    if runtimeSound and runtimeSound.Parent then
        return runtimeSound
    end

    local template = StaticAssetRegistry.GetInstance("sounds", "SlimeAmbience")
    runtimeSound = template:Clone()
    runtimeSound.Name = "SlimeAmbienceRuntime"
    runtimeSound.RollOffMaxDistance = 10000
    runtimeSound.Parent = SoundService
    return runtimeSound
end

function AmbienceService.Init(ctx)
    local entry = StaticAssetRegistry.GetEntry("sounds", "SlimeAmbience")
    if entry.soundId == UNCONFIGURED_SOUND_ID then
        ctx.Services.AmbienceService = AmbienceService
        return
    end

    local ok, sound = pcall(function()
        return ensureRuntimeSound()
    end)

    if ok and sound and not sound.IsPlaying then
        sound:Play()
    end

    ctx.Services.AmbienceService = AmbienceService
end

return AmbienceService
