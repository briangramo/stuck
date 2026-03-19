local ServerScriptService = game:GetService("ServerScriptService")

local Bootstrap = require(ServerScriptService.Server.Bootstrap)

local ctx = {
    build = 3,
    gameName = "Stuck Forever",
}

Bootstrap.Init(ctx)
