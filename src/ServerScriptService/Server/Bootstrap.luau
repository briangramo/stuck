local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local StaticAssetRegistry = require(ReplicatedStorage.Shared.Config.StaticAssetRegistry)

local WorldService = require(script.Parent.Services.WorldService)
local BridgeService = require(script.Parent.Services.BridgeService)
local StuckService = require(script.Parent.Services.StuckService)
local SpectateService = require(script.Parent.Services.SpectateService)
local PlayerService = require(script.Parent.Services.PlayerService)
local DistanceService = require(script.Parent.Services.DistanceService)
local LeaderboardService = require(script.Parent.Services.LeaderboardService)
local WorldStreamingService = require(script.Parent.Services.WorldStreamingService)
local AmbienceService = require(script.Parent.Services.AmbienceService)

local Bootstrap = {}

function Bootstrap.Init(ctx)
    local ok, errors = StaticAssetRegistry.ValidateAll()
    if not ok then
        error("Static asset validation failed:\n- " .. table.concat(errors, "\n- "))
    end

    ctx.Config = GameConfig
    ctx.State = {
        players = {},
        monuments = {},
    }
    ctx.Services = {}

    WorldService.Init(ctx)
    BridgeService.Init(ctx)
    StuckService.Init(ctx)
    SpectateService.Init(ctx)
    PlayerService.Init(ctx)
    DistanceService.Init(ctx)
    LeaderboardService.Init(ctx)
    WorldStreamingService.Init(ctx)
    AmbienceService.Init(ctx)

    return ctx
end

return Bootstrap
