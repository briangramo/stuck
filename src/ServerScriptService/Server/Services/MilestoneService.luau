local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StaticAssetRegistry = require(ReplicatedStorage.Shared.Config.StaticAssetRegistry)

local MilestoneService = {
    remote = nil,
}

function MilestoneService.UpdateDistance(state, distance)
    local ctx = MilestoneService.ctx
    if not ctx or not state or not state.player then
        return
    end

    local milestoneInterval = ctx.Config.MILESTONE_INTERVAL
    local currentMilestone = math.floor((distance or 0) / milestoneInterval)
    local lastMilestone = state.lastCelebratedMilestone or 0
    if currentMilestone <= lastMilestone then
        return
    end

    state.lastCelebratedMilestone = currentMilestone

    for milestoneIndex = lastMilestone + 1, currentMilestone do
        MilestoneService.remote:FireClient(state.player, {
            distance = milestoneIndex * milestoneInterval,
        })
    end
end

function MilestoneService.Init(ctx)
    MilestoneService.ctx = ctx
    MilestoneService.remote = StaticAssetRegistry.GetInstance("network", "DistanceMilestoneReached")
    ctx.Services.MilestoneService = MilestoneService
end

return MilestoneService
