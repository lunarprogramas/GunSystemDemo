local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controllers = script.Scripts.Controllers
local Modules = script.Scripts.Modules

-- made by @lunarprogramas (janslan)

local import = require(ReplicatedStorage.Shared.import)

local function start()
	import("set:Controllers", Controllers:GetChildren(), false)
	import("set:Modules", Modules:GetChildren(), false)
	import("set:Shared", ReplicatedStorage.Shared.Scripts:GetChildren(), true)

	warn("initializing Controllers")

	for _, ser in Controllers:GetChildren() do
		local mod = require(ser)

		local success, result = pcall(function()
			return mod:Init()
		end)

		if not success then
			warn(ser.Name, " - ", result)
		end

        warn("started", ser.Name)
		task.wait()
	end

	warn("starting Controllers")

	for _, ser in Controllers:GetChildren() do
		local mod = require(ser)

		local success, result = pcall(function()
			return mod:Start()
		end)

		if not success then
			warn(ser.Name, " - ", result)
		end
		task.wait()
	end

	workspace:SetAttribute("ClientDoneLoading", true)
end

if not workspace:GetAttribute("ServerDoneLoading") then
    workspace:GetAttributeChangedSignal("ServerDoneLoading"):Wait()
end

start()
