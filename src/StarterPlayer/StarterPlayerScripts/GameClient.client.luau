local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local clientModules = script.Parent:WaitForChild("Client")
local SpectateController = require(clientModules:WaitForChild("SpectateController"))

local ctx = {
    config = GameConfig,
    player = Players.LocalPlayer,
}

SpectateController.Init(ctx)
