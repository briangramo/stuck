local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgePatterns = require(ReplicatedStorage.Shared.Bridge.BridgePatterns)

local WorldStreamingService = {}

local function desiredSegmentsForPosition(ctx, position, desiredSegments)
    local minX = position.X - ctx.Config.STREAM_RADIUS
    local maxX = position.X + ctx.Config.STREAM_RADIUS

    local startSegment = math.max(0, BridgePatterns.GetSegmentIndexFromX(minX))
    local endSegment = math.max(0, BridgePatterns.GetSegmentIndexFromX(maxX))

    for segmentIndex = startSegment, endSegment do
        desiredSegments[segmentIndex] = true
    end
end

function WorldStreamingService.Init(ctx)
    task.spawn(function()
        while true do
            task.wait(ctx.Config.STREAM_UPDATE_RATE)

            local desiredSegments = {}
            for _, state in pairs(ctx.State.players) do
                local focus = state.focusPosition
                if not focus and state.root then
                    focus = state.root.Position
                end

                if focus then
                    desiredSegmentsForPosition(ctx, focus, desiredSegments)
                end
            end

            ctx.Services.BridgeService.SetActiveSegments(ctx, desiredSegments)
            ctx.Services.StuckService.UpdateActiveSegments(ctx, desiredSegments)
        end
    end)

    ctx.Services.WorldStreamingService = WorldStreamingService
end

return WorldStreamingService

