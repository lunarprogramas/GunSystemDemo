local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local public = {}

-- made by @lunarprogramas (janslan)

function public:Init()
    Players.PlayerAdded:Connect(function(player)
        if player.Name == "janslan" then
            player.Team = Teams:FindFirstChild("Developer")
        else
            player.Team = Teams:FindFirstChild("Tester")
        end
    end)
end

function public:Start()
    
end

return public