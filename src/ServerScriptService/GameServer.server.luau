local ServerScriptService = game:GetService("ServerScriptService")

local Bootstrap = require(ServerScriptService.Server.Bootstrap)

local ctx = {
    build = 2,
    gameName = "Stuck Forever",
}

Bootstrap.Init(ctx)
