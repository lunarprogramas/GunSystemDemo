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
	Threads = {},
}

local limbMap = {
	Head = 3,
	UpperTorso = 3,
	LowerTorso = 2.5,
	LeftUpperArm = 1.5,
	LeftLowerArm = 1.5,
	LeftHand = 1.5,
	RightUpperArm = 1.5,
	RightLowerArm = 1.5,
	RightHand = 1.5,
	LeftUpperLeg = 3,
	LeftLowerLeg = 2.5,
	LeftFoot = 2,
	RightUpperLeg = 3,
	RightLowerLeg = 2.5,
	RightFoot = 2,
}

-- made by @lunarprogramas (janslan)
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
			local reloadtime = config.ReloadTime

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
					ReloadTime = reloadtime,
					AnimationFireSpeed = config.AnimationFireSpeed -- only for primaries
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
					ReloadTime = reloadtime,
					RestTime = config.RestTime -- only in secondaries
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

	GunRemote.OnServerEvent:Connect(function(plr: Player, type, origin, tool, firerate)
		if type == "Fire" then
			local gun = getGunFromTable(tool)
			local bullet = ServerStorage.Guns:FindFirstChild("Bullet"):Clone()
			local determinedFirerate = false

			if not bullet then
				return warn("bullet not found")
			end

			if firerate == "Automatic" and gun.BurstType == "Automatic" then
				determinedFirerate = "Automatic"
			else
				determinedFirerate = "Single"
			end

			if determinedFirerate == "Single" then
				local ammo = tool:GetAttribute("Ammo")

				if ammo > 0 then
					local mousePosition = GunFunction:InvokeClient(plr, "MouseLocation")
					local cameraPosition = GunFunction:InvokeClient(plr, "CameraLocation")
					local direction = (mousePosition - cameraPosition).Unit * 500 -- 500 studs range, adjust as needed

					local raycastParams = RaycastParams.new()
					raycastParams.FilterType = Enum.RaycastFilterType.Exclude
					raycastParams.FilterDescendantsInstances = { tool, plr.Character }

					local result = workspace:Raycast(cameraPosition, direction, raycastParams)

					if result then
						local hitPart = result.Instance
						if hitPart and hitPart.Parent:FindFirstChild("Humanoid") then
							local player = Players:GetPlayerFromCharacter(hitPart.Parent)
							local limbMultiplier = limbMap[hitPart] or 1
							if player ~= plr then
								local damage = math.floor(gun.Damage * limbMultiplier)
								GunFunction:InvokeClient(plr, "DamageIndicator", hitPart.Parent, damage)
								hitPart.Parent.Humanoid.Health -= damage
							end
						end
					end

					tool.Muzzle.Flash.Enabled = true
					tool.Muzzle.LightEffect:Emit(1)
					tool.Muzzle.Audio:Play()
					tool:SetAttribute("Ammo", ammo - 1)
					task.delay(0.4, function()
						tool.Muzzle.Flash.Enabled = false
					end)
				else
					tool.Muzzle.GunEmpty:Play()
				end
			elseif determinedFirerate == "Automatic" then
				public.Threads[plr] = task.spawn(function()
					while tool:GetAttribute("Ammo") > 0 do
						local ammo = tool:GetAttribute("Ammo")
						task.wait(gun.FireRate)

						local mousePosition = GunFunction:InvokeClient(plr, "MouseLocation")
						local cameraPosition = GunFunction:InvokeClient(plr, "CameraLocation")
						local direction = (mousePosition - cameraPosition).Unit * 500 -- 500 studs range, adjust as needed

						local raycastParams = RaycastParams.new()
						raycastParams.FilterType = Enum.RaycastFilterType.Exclude
						raycastParams.FilterDescendantsInstances = { tool, plr.Character }

						local result = workspace:Raycast(cameraPosition, direction, raycastParams)

						if result then
							local hitPart = result.Instance
							if hitPart and hitPart.Parent:FindFirstChild("Humanoid") then
								local player = Players:GetPlayerFromCharacter(hitPart.Parent)
								local limbMultiplier = limbMap[hitPart.Name] or 1
								if player ~= plr then
									local damage = math.floor(gun.Damage * limbMultiplier)
									GunFunction:InvokeClient(plr, "DamageIndicator", hitPart.Parent, damage)
									hitPart.Parent.Humanoid.Health -= damage
								end
							end
						end

						tool.Muzzle.Flash.Enabled = true
						tool.Muzzle.LightEffect:Emit(1)
						tool.Muzzle.Audio:Play()
						tool:SetAttribute("Ammo", ammo - 1)
						task.delay(0.4, function()
							tool.Muzzle.Flash.Enabled = false
						end)
					end

					if tool:GetAttribute("Ammo") == 0 then
						tool.Muzzle.GunEmpty:Play()
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

	GunFunction.OnServerInvoke = function(plr, request, ...)
		local args = { ... }
		if request == "GetGunDetails" then
			return getGunFromTable(args[1])
		end
	end
end

function public:Start() end

return public
