local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local import = require(ReplicatedStorage.Shared.import)

local Network = import("Shared/Network")
local ServerRF: RemoteFunction = Network.GetRemoteFunction("Server_RF")

local command = {}

-- made by @lunarprogramas (janslan)

command = {
    Name = "shutdown",
    Permissions = "Owner",
    RawCommand = "/shutdown"
}

function command:Execute()
    ServerRF:InvokeServer("Shutdown")
    return true
end

return command