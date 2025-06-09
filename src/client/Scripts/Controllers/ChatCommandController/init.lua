local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local public = {}

public = {
	Commands = {},
}

-- made by @lunarprogramas (janslan)

local function getCommandFromMessage(msg)
    local split = string.split(msg, " ")
	for name, cmd in public.Commands do
		local cmdSplit = string.split(cmd.RawCommand, " ")
		if split[1] == cmdSplit[1] then
			if cmd.Args > 0 then
				return cmd:Run(split[2])
			else
				return cmd:Run()
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
