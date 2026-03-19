local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgePatterns = require(ReplicatedStorage.Shared.Bridge.BridgePatterns)

local DistanceService = {}

function DistanceService.Init(ctx)
    local accumulator = 0

    RunService.Heartbeat:Connect(function(deltaTime)
        accumulator += deltaTime
        if accumulator < ctx.Config.DISTANCE_UPDATE_RATE then
            return
        end
        accumulator = 0

        for _, state in pairs(ctx.State.players) do
            if not state.isStuck and state.root and state.humanoid and state.humanoid.Health > 0 then
                local position = state.root.Position
                state.lastRootPosition = position
                state.focusPosition = position
                state.currentDistance = BridgePatterns.GetDistanceFromPosition(position)
                state.farthestDistance = math.max(state.farthestDistance or 0, state.currentDistance)
                ctx.Services.MilestoneService.UpdateDistance(state, state.farthestDistance)

                if position.Y <= ctx.Config.FALL_Y_THRESHOLD then
                    ctx.Services.StuckService.MarkPlayerStuck(ctx, state.player)
                end
            end
        end
    end)

    ctx.Services.DistanceService = DistanceService
end

return DistanceService
