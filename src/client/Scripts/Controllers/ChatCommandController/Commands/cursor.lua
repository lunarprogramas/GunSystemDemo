local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local import = require(ReplicatedStorage.Shared.import)

local GunController = import("Client/Controllers/GunController")

local command = {}

-- made by @lunarprogramas (janslan)

command = {
    Name = "cursor",
    Permissions = "All",
    RawCommand = "!cursor $"
}

function command:Execute(img)
    GunController:ChangeCursor(img)
    return true
end

return command