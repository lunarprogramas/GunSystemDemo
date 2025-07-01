local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local import = require(ReplicatedStorage.Shared.import)

local Network = import("Shared/Network")
local LeaderboardController = import("Client/Controllers/LeaderboardController")

local command = {}

-- made by @lunarprogramas (janslan)

command = {
    Name = "leaderboard",
    Permissions = {"All"},
    RawCommand = "!leaderboard"
}

function command:Execute()
    LeaderboardController:SetLeaderboard()
    return true
end

return command