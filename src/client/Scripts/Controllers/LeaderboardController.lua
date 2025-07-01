local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local Controller = {}

local import = require(ReplicatedStorage.Shared.import)
local HasPermission = import("Shared/Permissions")

local UI
local Player = Players.LocalPlayer

local TeamIcons = {
	["Developer"] = "rbxassetid://17399844238",
	["Administrator"] = "rbxassetid://17401665157"
}

local PlayerIcons = {
	-- ["Developer"] = {
	-- 	Permissions = "Owner",
	-- 	Icon = "rbxassetid://17399844238"
	-- }
}

local HiddenPermissions = {
	"Owner",
}

local ViewPermissions = { "Owner" }

local List = {}
local connections = {}
local attemptedToView = {}
local viewing
local viewingPlayer
local leaderboardState = true

local function getRank(plr: Player)
	if plr.UserId == game.CreatorId then
		return `<b><font color="rgb(255,255,0)">{string.upper(plr.Name)}</font> (OWNER)</b>`
	else
		return `<b>{string.upper(plr.Name)}</b>`
	end
end

local function viewPlayer(plr: Player, button: TextButton)
	if not HasPermission(Player, ViewPermissions) then
		return
	end
	if plr == Player and viewing then
		workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid
		viewing.TextLabel.Text = getRank(viewingPlayer)
		viewing = false
		viewingPlayer = false
		return
	end

	if not attemptedToView[plr] and not viewing then
		attemptedToView[plr] = true
		button.TextLabel.Text = getRank(plr) .. " [PRESS ONCE MORE TO VIEW/UNVIEW]"

		connections["delay"] = task.delay(5, function()
			attemptedToView[plr] = false
			button.TextLabel.Text = getRank(plr)
		end)
	else
		if viewing then
			workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid
			viewing = false
			viewingPlayer = false
			button.TextLabel.Text = getRank(plr)
			return
		end

		attemptedToView[plr] = nil
		button.TextLabel.Text = getRank(plr) .. " [VIEWING]"
		task.cancel(connections["delay"])
		workspace.CurrentCamera.CameraSubject = plr.Character.Humanoid
		viewing = button
		viewingPlayer = plr
	end
end

local function updateLeaderboard()
	local maxPlayers = #Players:GetPlayers()

	-- clear current values
	List = {}

	for _, ui in UI:GetChildren() do
		if ui:IsA("Frame") or ui:IsA("TextButton") then
			ui:Destroy()
		end
	end

	for _, plr: Player in Players:GetPlayers() do
		for _, team in Teams:GetTeams() do
			if not List[team.Name] then
				List[team.Name] = {}
			end

			if not List[team.Name].Players then
				List[team.Name].Players = {}
			end

			if plr and plr.Team and plr.Team == team then
				table.insert(List[plr.Team.Name].Players, { player = plr })
			end
		end
	end

	-- setup the layout order
	for i = 1, maxPlayers do
		for _, team in List do
			if not team._teamIndex then
				team._teamIndex = {}
			end

			team._teamIndex = i
			i = i + 1

			for _, plr in team.Players do
				plr._playerIndex = i
				i = i + 1
			end
		end
	end

	-- sort the table alpabetically
	-- sorts the team names
	table.sort(List)

	for _, team in List do -- sort players
		table.sort(team.Players, function(a, b)
			return a.player.Name:lower() < b.player.Name:lower()
		end)
	end

	-- once the List has been organised then we will display it
	for name, team in List do
		local hidden = Teams[name]:GetAttribute("Hidden")

		if not leaderboardState then
			leaderboardState = true
			UI.Parent.Enabled = true
		end

		if (hidden and HasPermission(Player, HiddenPermissions)) or not hidden then
			local hasTeamIcon = TeamIcons[name] and true or false
			local teamUI = hasTeamIcon and UI.Template.TeamWithIcon:Clone() or UI.Template.TeamWithoutIcon:Clone()
			teamUI.Parent = UI
			teamUI.Name = name
			teamUI.TextLabel.Text = string.upper(name)
			teamUI.LayoutOrder = team._teamIndex
			teamUI.BackgroundColor3 = Teams[name].TeamColor.Color

			if hasTeamIcon then
				teamUI.TeamIcon.Visible = true
				teamUI.TeamIcon.Image = TeamIcons[name]
			end

			teamUI.Visible = true

			for _, plr in team.Players do
				local hasPlayerIcon = false
				for _, icon in PlayerIcons do
					if HasPermission(Player, icon.Permissions) then
						hasPlayerIcon = icon.Icon
					end
				end

				local plrUI: TextButton = UI.Template.Player:Clone()
				plrUI.Parent = UI
				plrUI.Name = plr.player.Name
				plrUI.TextLabel.Text = getRank(plr.player)
				plrUI.LayoutOrder = plr._playerIndex
				if hasPlayerIcon then
					plrUI.PlayerIcon.Visible = true
					plrUI.PlayerIcon.Image = hasPlayerIcon
				end
				plrUI.Visible = true
				connections[plr.player.Name] = plrUI.MouseButton1Click:Connect(function()
					viewPlayer(plr.player, plrUI)
				end)
			end
		end
	end

	-- hide the leaderboard if nothing is there
	local count = 0
	for _, ui in UI:GetChildren() do
		if ui:IsA("Frame") or ui:IsA("TextButton") then
			count = count + 1
		end
	end

	if count == 0 then
		leaderboardState = false
		UI.Parent.Enabled = false
	end
end

function Controller:SetLeaderboard()
	leaderboardState = not leaderboardState
	UI.Parent.Enabled = leaderboardState
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not leaderboardState)
end

function Controller:Init()
	if not UI then
		UI = ReplicatedStorage:FindFirstChild("Leaderboard"):Clone()
		UI.Parent = Player.PlayerGui
		UI.Enabled = true
		UI = UI.ScrollingFrame
		if not UI then
			return warn("Unable to initialise leaderboard due to the asset not found!")
		end
	end

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not gameProcessedEvent then
			if input.KeyCode == Enum.KeyCode.Tab and leaderboardState then
				UI.Parent.Enabled = not UI.Parent.Enabled
			end
		end
	end)
end

function Controller:Start()
	Players.PlayerAdded:Connect(function(player)
		updateLeaderboard()
		connections[("teamchange_%s"):format(player.UserId)] = player:GetPropertyChangedSignal("Team"):Connect(function()
			updateLeaderboard()
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		updateLeaderboard()
		connections[("teamchange_%s"):format(player.UserId)]:Disconnect()
		connections[("teamchange_%s"):format(player.UserId)] = nil
	end)

	Player:GetPropertyChangedSignal("Team"):Connect(updateLeaderboard)
	updateLeaderboard()
end

return Controller
