local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Shared.import)
local Network = import("Shared/Network")

local DummyRF: RemoteFunction = Network.GetRemoteFunction("Dummy_RF")

local public = {
    Dummys = {},
	DefaultDummy = nil
}

-- made by @lunarprogramas (janslan)

function public:Init()
    for _, char: Model in CollectionService:GetTagged("Dummy") do
        public.Dummys[char] = char
		public.DefaultDummy = char:Clone()
        local charHumanoid: Humanoid = char:FindFirstChildOfClass("Humanoid")
        if charHumanoid then
            charHumanoid.Died:Connect(function()
                local new = char:Clone()
                new.Parent = workspace
            end)
        end
    end

	CollectionService:GetInstanceAddedSignal("Dummy"):Connect(function(char)
		public.Dummys[char] = char
        local charHumanoid: Humanoid = char:FindFirstChildOfClass("Humanoid")
        if charHumanoid then
            charHumanoid.Died:Connect(function()
                local new = char:Clone()
                new.Parent = workspace
            end)
        end
	end)

	DummyRF.OnServerInvoke = function(plr, ...)
		local args = { ... }

		if args[1] == "Spawn" then
			local char = public.DefaultDummy:Clone()
			char.Parent = workspace
		end
	end
end

function public:Start() end

return public