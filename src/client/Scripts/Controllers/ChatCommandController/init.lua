local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local public = {}

local import = require(ReplicatedStorage.Shared.import)
local HasPermission = import("Shared/Permissions")

public = {
	Commands = {},
}

-- made by @lunarprogramas (janslan)

local function getCommandFromMessage(msg)
	local split = string.split(msg, " ")
	for name, cmd in public.Commands do
		local cmdSplit = string.split(cmd.RawCommand, " ")
		if split[1] == cmdSplit[1] then
			if HasPermission(Players.LocalPlayer, cmd.Permissions) then
				if cmd.Args > 0 then
					return cmd:Run(split[2], split[3] or nil)
				else
					return cmd:Run()
				end
			end
		end
	end
end

function public:Init()
	local commands = script.Commands:GetChildren()

	for _, cmd in commands do
		cmd = require(cmd)
		public.Commands[cmd.Name] = cmd
		public.Commands[cmd.Name].Run = cmd.Execute

		if string.find(cmd.RawCommand, "$") then
			local _, count = string.gsub(cmd.RawCommand, "%$", "")
			public.Commands[cmd.Name].Args = count
		end
	end

	TextChatService.SendingMessage:Connect(function(ChatMsg)
		getCommandFromMessage(ChatMsg.Text)
	end)
end

function public:Start() end

return public
