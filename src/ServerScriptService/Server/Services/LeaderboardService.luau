local LeaderboardService = {}

local function scoreForState(state)
    return math.max(state.farthestDistance or 0, state.stuckDistance or 0)
end

local function sortEntries(left, right)
    if left.distance == right.distance then
        return left.name < right.name
    end

    return left.distance > right.distance
end

function LeaderboardService.Init(ctx)
    task.spawn(function()
        while true do
            task.wait(ctx.Config.LEADERBOARD_UPDATE_RATE)

            local entries = {}
            for _, state in pairs(ctx.State.players) do
                table.insert(entries, {
                    name = state.player.DisplayName,
                    distance = scoreForState(state),
                })
            end

            table.sort(entries, sortEntries)

            for rank, row in ipairs(ctx.World.LeaderboardRows) do
                local entry = entries[rank]
                if entry then
                    row.Text = string.format("%d | %s | %d", rank, entry.name, entry.distance)
                else
                    row.Text = string.format("%d | --- | 0", rank)
                end
            end
        end
    end)

    ctx.Services.LeaderboardService = LeaderboardService
end

return LeaderboardService
