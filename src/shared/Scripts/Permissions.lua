-- Permissions system
-- made by @lunarprogramas (janslan)

local Permissions = {}

function Permissions (Player, Permission)
    if typeof(Permission) == "string" then
        if string.find(Permission, "Gamepass") then
            local s = string.split(Permission, ":")
            return Player:GetAttribute(("Owns_%s"):format(s[2]))
        elseif string.find(Permission, "User") then
            local s = string.split(Permission, ":")
            return Player.UserId == tonumber(s[2])
        elseif string.find(Permission, "Team") then
            local s = string.split(Permission, ":")
            return Player.Team.Name == s[2]
        elseif Permission == "All" then
            return true
        elseif Permission == "Owner" then
            return Player.UserId == game.CreatorId
        end
    else
        for _, perm in Permission do
            if string.find(perm, "Gamepass") then
                local s = string.split(perm, ":")
                return Player:GetAttribute(("Owns_%s"):format(s[2]))
            elseif string.find(perm, "User") then
                local s = string.split(perm, ":")
                return Player.UserId == tonumber(s[2])
            elseif string.find(perm, "Team") then
                local s = string.split(perm, ":")
                return Player.Team.Name == s[2]
            elseif perm == "All" then
                return true
            elseif perm == "Owner" then
                return Player.UserId == game.CreatorId
            end
        end
    end
end

return Permissions