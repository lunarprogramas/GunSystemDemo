local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local import = require(ReplicatedStorage.Shared.import)

local Network = import("Shared/Network")
local ServerRF: RemoteFunction = Network.GetRemoteFunction("Server_RF")

local command = {}

-- made by @lunarprogramas (janslan)

command = {
    Name = "kick",
    Permissions = "Owner",
    RawCommand = "/kick $ $"
}

function command:Execute(plr, reason)
    for _, player in Players:GetPlayers() do
        if string.lower(player.Name) == string.lower(plr) then
            plr = player
        elseif plr == "me" then
            plr = Players.LocalPlayer
        end
    end

    if typeof(plr) == "string" then
        return warn("Unable to find this player.")
    end

    ServerRF:InvokeServer("Kick", plr, reason or "No reason provided.")
    return true
end

return command