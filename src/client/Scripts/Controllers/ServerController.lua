local Players = game:GetService("Players")
local public = {}

-- made by @lunarprogramas (janslan)

function public:Init()
	local UI = Players.LocalPlayer.PlayerGui:WaitForChild("important")
	if not UI then
		return
	end

    UI.ServerVersion.Visible = true
    UI.ServerVersion.AnchorPoint = Vector2.new(0,0)
    UI.ServerVersion.Position = UDim2.new(0, 130, 0, 23)

    UI.ServerVersion.Text = workspace:GetAttribute("ServerInfoText")

    workspace:GetAttributeChangedSignal("ServerInfoText"):Connect(function()
        UI.ServerVersion.Text = workspace:GetAttribute("ServerInfoText")
    end)
end

function public:Start() end

return public
