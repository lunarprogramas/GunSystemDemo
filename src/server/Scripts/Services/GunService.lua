local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local public = {}

local import = require(ReplicatedStorage.Shared.import)
local Permissions = import("Shared/Permissions")
local Network = import("Shared/Network")

local GunRemote: RemoteEvent = Network.GetRemoteEvent("GunRE")
local GunFunction: RemoteFunction = Network.GetRemoteFunction("GunRF")

public = {
	Primaries = {},
	Secondaries = {},
	Debounces = {},
	CeaseFires = {},
	Threads = {},
}

-- in an ideal world you would never use rcl :D
-- and in an ideal word there are better practices and i dont declare myself as a god in programming this is just how I would approximately do if not a tad better on an actual project

local function getGunFromTable(gunModel)
	for name, gun in public.Primaries do
		if name == gunModel.Name then
			return gun
		end
	end

	for name, gun in public.Secondaries do
		if name == gunModel.Name then
			return gun
		end
	end

	return nil
end

local function giveGun(player, model)
	local clone = model.Model:Clone()

	clone:RemoveTag("Gun")
	clone:AddTag("OwnedGun")
	clone:SetAttribute("Ammo", model.MaxAmmo)

	local animFolder = Instance.new("Folder", clone)
	animFolder.Name = "Animations"

	for name, anim in model.Animations do
		local animation = Instance.new("Animation")
		animation.AnimationId = anim
		animation.Name = name
		animation.Parent = animFolder
	end

	clone.Parent = player.Backpack
	warn("gave ", player.Name, "a", model.Model.Name)
end

local function checkIfCanHaveGun(player: Player)
	for _, gun in public.Primaries do
		if Permissions(player, gun.Permissions) then
			giveGun(player, gun)
		end
	end

	for _, gun in public.Secondaries do
		if Permissions(player, gun.Permissions) then
			giveGun(player, gun)
		end
	end
end

function public:Init()
	for _, gun in CollectionService:GetTagged("Gun") do
		if gun:IsA("Tool") then
			local config = gun:FindFirstChild("Settings")
			local perms = gun:FindFirstChild("Permissions")

			if not config then
				warn("cant find config for ", gun.Name)
			end

			if not perms then
				warn("no perms for ", gun.Name, " going to fallback perms")
				perms = {}
			else
				perms = require(perms)
			end

			config = require(config)

			local guntype = gun:GetAttribute("Type") or config.Type
			local name = config.Name
			local burstType = config.BurstType
			local damage = config.Damage
			local anims = config.Animations
			local model = gun
			local maxammo = config.MaxAmmo
			local firerate = config.FireRate

			if firerate == 0 then
				return warn("firerate cannot be 0 seconds otherwise you will brick everything - gun:", name)
			end

			if guntype == "Primary" then
				public.Primaries[name] = {
					Damage = damage,
					BurstType = burstType,
					Animations = anims,
					Permissions = perms,
					Model = model,
					MaxAmmo = maxammo,
					FireRate = firerate,
				}
			elseif guntype == "Secondary" then
				public.Secondaries[name] = {
					Damage = damage,
					BurstType = burstType,
					Animations = anims,
					Permissions = perms,
					Model = model,
					MaxAmmo = maxammo,
					FireRate = firerate,
				}
			else
				warn("gun type ", guntype, " was not recognized")
			end

			warn("initialized gun ", name)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			checkIfCanHaveGun(player)
		end)
	end)

	GunRemote.OnServerEvent:Connect(function(plr: Player, type, origin, tool)
		if type == "Fire" then
			local gun = getGunFromTable(tool)
			local bullet = ServerStorage.Guns:FindFirstChild("Bullet"):Clone()

			if not bullet then
				return warn("bullet not found")
			end

			if gun.BurstType == "Single" then
				local ammo = tool:GetAttribute("Ammo")

				if ammo > 0 then
					tool:SetAttribute("Ammo", ammo - 1)
					bullet.Parent = tool
					public.Debounces[bullet] = {}
					bullet:SetPrimaryPartCFrame(tool.Muzzle.CFrame)

					local tweenInfo = TweenInfo.new(gun.FireRate, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local cf = CFrame.new(origin)

					local tween = TweenService:Create(bullet.PrimaryPart, tweenInfo, { CFrame = cf })

					tool.Muzzle.Flash.Enabled = true
					tool.Muzzle.Audio:Play()

					bullet.Parent = workspace
					tween:Play()

					local bulletCore: Part = bullet.PrimaryPart

					bulletCore.Touched:Connect(function(part)
						if part.Parent:FindFirstChild("Humanoid") then
							local player = Players:GetPlayerFromCharacter(part.Parent)
							if not public.Debounces[bullet][player] then
								public.Debounces[bullet][player] = true
								local currentHealth = part.Parent:FindFirstChild("Humanoid").Health
								part.Parent:FindFirstChild("Humanoid").Health = currentHealth - gun.Damage
							end
						end
					end)

					tween.Completed:Connect(function()
						bullet:Destroy()
						tool.Muzzle.Flash.Enabled = false
						public.Debounces[bullet] = nil
					end)
				else
					tool.Muzzle.GunEmpty:Play()
				end
			elseif gun.BurstType == "Automatic" then
				local ammo = tool:GetAttribute("Ammo")

				warn(1)

				public.Threads[plr] = task.spawn(function()
					while tool:GetAttribute("Ammo") > 0 do
						task.wait(gun.FireRate)

						tool:SetAttribute("Ammo", ammo - 1)
						bullet = bullet:Clone()
						bullet.Parent = workspace
						public.Debounces[bullet] = {}
						bullet.CFrame = tool.Muzzle.CFrame
						bullet:AddTag(("%s_Bullets"):format(plr.Name))

						local tweenInfo = TweenInfo.new(gun.FireRate, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

						local mouse = GunFunction:InvokeClient(plr, "MouseLocation")

						local cf = CFrame.new(mouse)

						local tween = TweenService:Create(bullet, tweenInfo, { CFrame = cf })

						tool.Muzzle.Flash.Enabled = true
						tool.Muzzle.Audio:Play()

						tween:Play()

						local bulletCore: Part = bullet

						bulletCore.Touched:Connect(function(part)
							if part.Parent:FindFirstChild("Humanoid") then
								local player = Players:GetPlayerFromCharacter(part.Parent)
								if not public.Debounces[bullet][player] then
									public.Debounces[bullet][player] = true
									local currentHealth = part.Parent:FindFirstChild("Humanoid").Health
									part.Parent:FindFirstChild("Humanoid").Health = currentHealth - gun.Damage
								end
							end
						end)

						tween.Completed:Connect(function()
							public.Debounces[bullet] = {}
							bullet:Destroy()
							tool.Muzzle.Flash.Enabled = false
						end)
					end
				end)
			end
		elseif type == "Reload" then
			local gun = getGunFromTable(tool)
			tool:SetAttribute("Ammo", gun.MaxAmmo)
		elseif type == "Stop" then
            if public.Threads[plr] then
                task.cancel(public.Threads[plr])
                public.Threads[plr] = nil
            end

			for _, bullet in CollectionService:GetTagged(("%s_Bullets"):format(plr.Name)) do
				bullet:Destroy()
			end
		end
	end)
end

function public:Start() end

return public
