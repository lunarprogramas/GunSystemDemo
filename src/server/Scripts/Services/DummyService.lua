local CollectionService = game:GetService("CollectionService")
local public = {
	Dummys = {},
}

function public:Init()
    local function chain()
        for _, char: Model in CollectionService:GetTagged("Dummy") do
		public.Dummys[char] = char
		local charHumanoid: Humanoid = char.Humanoid
		charHumanoid.HealthChanged:Connect(function()
			if charHumanoid.Health == 0 then
                charHumanoid:Destroy()
				local new = public.Dummys[char]:Clone()
				new.Parent = workspace
                new.Humanoid.Health = 100
                chain()
			end
		end)
	end
    end
    chain()
end

function public:Start() end

return public
