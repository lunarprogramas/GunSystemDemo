-- Manager for all functions, events.
-- made by @lunarprogramas (janslan)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Network = {}

local Events = {
	["BindableEvents"] = {},
	["BindableFunction"] = {},
	["RemoteEvent"] = {},
	["RemoteFunction"] = {},
}

local store

if ReplicatedStorage:FindFirstChild("Network") then
	store = ReplicatedStorage:FindFirstChild("Network")
else
	store = Instance.new("Folder")
	store.Parent = ReplicatedStorage
	store.Name = "Network"
end

function Network.GetRemoteEvent(name)
	for _, event in store:GetDescendants() do
		if event.Name == name then
			return event
		end
	end

	if RunService:IsServer() then
		local Event = Instance.new("RemoteEvent")
		Event.Name = name
		Event.Parent = store
		table.insert(Events.RemoteEvent, Event)
		return Event
	end
end

function Network.GetRemoteFunction(name)
	for _, event in store:GetDescendants() do
		if event.Name == name then
			return event
		end
	end

	if RunService:IsServer() then
		local Event = Instance.new("RemoteFunction")
		Event.Name = name
		Event.Parent = store
		table.insert(Events.RemoteFunction, Event)
		Event:SetAttribute("ID", math.random(1, 100))
		return Event
	end
end

function Network.GetBindableEvent(name)
	for _, event in store:GetDescendants() do
		if event.Name == name then
			return event
		end
	end

	if RunService:IsServer() then
		local Event = Instance.new("BindableEvent")
		Event.Name = name
		Event.Parent = store
		table.insert(Events.BindableEvents, Event)
		return Event
	end
end

function Network.GetBindableFunction(name)
	for _, event in store:GetDescendants() do
		if event.Name == name then
			return event
		end
	end

	if RunService:IsServer() then
		local Event = Instance.new("BindableFunction")
		Event.Name = name
		Event.Parent = store
		table.insert(Events.BindableFunction, Event)
		return Event
	end
end

return Network