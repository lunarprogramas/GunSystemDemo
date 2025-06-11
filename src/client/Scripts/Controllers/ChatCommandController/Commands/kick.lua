local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local import = require(ReplicatedStorage.Shared.import)

local Network = import("Shared/Network")
local ServerRF: RemoteFunction = Network.GetRemoteFunction("Server_RF")

local command = {}

-- made by @lunarprogramas (janslan)

command = {
    Name = "kick",
    Permissions = {"User:294406038"},
    RawCommand = "!!!!kick $ $"
}

function command:Execute(plr, reason)
    for _, player in Players:GetPlayers() do
        if player.Name == plr then
            plr = player
        end
    end

    if typeof(plr) == "string" then
        return warn("Unable to find this player.")
    end

    ServerRF:InvokeServer("Kick", plr, reason or "No reason provided.")
    return true
end

return command