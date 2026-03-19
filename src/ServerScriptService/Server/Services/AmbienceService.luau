local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StaticAssetRegistry = require(ReplicatedStorage.Shared.Config.StaticAssetRegistry)

local AmbienceService = {}
local UNCONFIGURED_SOUND_ID = "rbxassetid://0"

function AmbienceService.Init(ctx)
    local entry = StaticAssetRegistry.GetEntry("sounds", "SlimeHum")
    if entry.soundId == UNCONFIGURED_SOUND_ID then
        ctx.Services.AmbienceService = AmbienceService
        return
    end

    local ok, sound = pcall(function()
        return StaticAssetRegistry.GetInstance("sounds", "SlimeHum")
    end)

    if ok and sound and not sound.IsPlaying then
        sound:Play()
    end

    ctx.Services.AmbienceService = AmbienceService
end

return AmbienceService
