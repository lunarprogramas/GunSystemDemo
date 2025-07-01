local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local import = require(ReplicatedStorage.Shared.import)

local Network = import("Shared/Network")
local ServerRF: RemoteFunction = Network.GetRemoteFunction("Server_RF")

local command = {}

-- made by @lunarprogramas (janslan)

command = {
	Name = "assignteam",
	Permissions = "Owner",
	RawCommand = "/assignteam $ $",
}

function command:Execute(plr, team)
	if plr == "me" then
		plr = Players.LocalPlayer
	else
		for _, player in Players:GetPlayers() do
			if string.lower(player.Name) == string.lower(plr) then
				plr = player
			else
				return warn("Unable to find this player.")
			end
		end
	end

	for _, t in Teams:GetTeams() do
		if string.lower(t.Name) == string.lower(team) then
			team = t
			break
		end

		t = Teams:FindFirstChild("Tester") -- callback
	end

	if typeof(plr) == "string" then
		return warn("Unable to find this player.")
	end

	ServerRF:InvokeServer("Team", plr, team)
	return true
end

return command
