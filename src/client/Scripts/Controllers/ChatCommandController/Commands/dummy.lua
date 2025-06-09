local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Shared.import)
local Network = import("Shared/Network")

local DummyRF: RemoteFunction = Network.GetRemoteFunction("Dummy_RF")

local command = {}

-- made by @lunarprogramas (janslan)

command = {
    Name = "dummy",
    Permissions = "All",
    RawCommand = "!dummy"
}

function command:Execute()
    DummyRF:InvokeServer("Spawn")
    return true
end

return command