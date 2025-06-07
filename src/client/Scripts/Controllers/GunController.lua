local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local public = {}

local import = require(ReplicatedStorage.Shared.import)
local Network = import("Shared/Network")

local GunRemote = Network.GetRemoteEvent("GunRE")
local GunFunction: RemoteFunction = Network.GetRemoteFunction("GunRF")

function public:Init()
    GunFunction.OnClientInvoke = function(request)
        if request == "MouseLocation" then
            return Players.LocalPlayer:GetMouse().Hit.Position
        end
    end

	Players.LocalPlayer.CharacterAdded:Connect(function(character)
		for _, tool: Tool in Players.LocalPlayer.Backpack:GetChildren() do
			warn(tool)
			if tool:HasTag("OwnedGun") then
				tool.Equipped:Connect(function(mouse)
					local animator: Animator = character.Humanoid.Animator
					local fire = animator:LoadAnimation(tool.Animations.Fire)
					local equip = animator:LoadAnimation(tool.Animations.Equipt)

					equip:Play()

					ContextActionService:BindAction("Reload", function()
						GunRemote:FireServer("Reload", nil, tool)
					end, false, Enum.KeyCode.R)

					mouse.Button1Down:Connect(function()
						warn(1)
						fire:Play()
						GunRemote:FireServer("Fire", mouse.Hit.Position, tool)
					end)

					mouse.Button1Up:Connect(function()
						GunRemote:FireServer("Stop", nil, tool)
					end)
				end)

                tool.Unequipped:Connect(function()
                    ContextActionService:UnbindAction("Reload")
                    GunRemote:FireServer("Stop", nil, tool)
                end)
			end
		end
	end)
end

function public:Start() end

return public
