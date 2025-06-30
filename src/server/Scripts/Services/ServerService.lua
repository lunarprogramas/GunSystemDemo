local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local public = {}

local import = require(ReplicatedStorage.Shared.import)
local Network = import("Shared/Network")
local HasPermission = import("Shared/Permissions")

local ServerRF: RemoteFunction = Network.GetRemoteFunction("Server_RF")

local function getServerVersion()
    return ReplicatedStorage:GetAttribute("Version") or "Unknown"
end

-- made by @lunarprogramas (janslan)

local function getServerVersionColors(color: string)
    if color == "Blue" then
        return "rgb(92, 204, 193)"
    elseif color == "Green" then
        return "rgb(49, 176, 58)"
    elseif color == "Amber" then
        return "rgb(176, 136, 49)"
    end
end

local function GetServerType()
    if RunService:IsStudio() then
        return "Studio Server"
    elseif game.PrivateServerOwnerId ~= 0 then
        return "Private Server"
    else
        return "Standard Server"
    end
end

local function GetAbbreviationServerType()
    if GetServerType() == "Studio Server" then
        local color = getServerVersionColors("Blue")
        return `<b><font color="{color}">[STUDIO]</font></b>`
    elseif GetServerType() == "Private Server" then
        local color = getServerVersionColors("Amber")
        return `<b><font color="{color}">[PRIVATE SERVER]</font></b>`
    else
        local color = getServerVersionColors("Green")
        return `<b><font color="{color}">[LIVE]</font></b>`
    end
end

local function SetupVersionText()
    local Version = getServerVersion()
    local Abbreviation = GetAbbreviationServerType()
    return `GunSystemRCL ~ {Version} {Abbreviation}`
end

function public:KickPlayer(plr, reason)
   plr:Kick(`[GunSystemDemo] ~ You have been kicked because:\n{reason}`)
end

function public:Shutdown()
    for _, plr in Players:GetPlayers() do
        plr:Kick("This server is shutting down...")
    end
end

function public:Team(plr, team)
    plr.Team = team
end

function public:Init()
    workspace:SetAttribute("ServerInfoText", SetupVersionText())

    ServerRF.OnServerInvoke = function(plr, ...)
        if not HasPermission(plr, {"Team:Developer"}) then
            plr:Kick("you should not be able to access this.")
        end

        local args = { ... }
        if args[1] == "Kick" then
            self:KickPlayer(args[2], args[3])
        elseif args[1] == "Shutdown" then
            self:Shutdown()
        elseif args[1] == "Team" then
            self:Team(args[2], args[3])
        end
    end
end

function public:Start()
    
end

return public