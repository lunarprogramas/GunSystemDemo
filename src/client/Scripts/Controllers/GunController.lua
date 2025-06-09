local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local public = {}

-- made by @lunarprogramas (janslan)

local import = require(ReplicatedStorage.Shared.import)
local Network = import("Shared/Network")
local TweenUI = import("Shared/TweenUI")

local GunRemote = Network.GetRemoteEvent("GunRE")
local GunFunction: RemoteFunction = Network.GetRemoteFunction("GunRF")

local reloading, fire, equip, reload, click, firerateSwitch, fired, hasShownIndicator
local UI
local light = false

local connections = {}
local animationCache = {}

local initializedGuns = {}

local defaultcursor = "rbxassetid://16717300045"
local cursor = defaultcursor
local clickSound = "rbxassetid://421058925"

local switchFirerateSound = "rbxassetid://73801435898712"

local firerate = "N/A"
local canSwitchFirerate = false

local firerates = {
	[1] = "Automatic",
	[2] = "Single",
}

local function showAndSetupUi(tool: Tool)
	local gunDetails = GunFunction:InvokeServer("GetGunDetails", tool)

	firerate = gunDetails.BurstType == "Automatic" and firerates[1] or firerates[2]
	canSwitchFirerate = firerate == "Automatic" and true or false

	UI = Players.LocalPlayer.PlayerGui:FindFirstChild("GunUI")

	if not UI then
		UI = ReplicatedStorage:FindFirstChild("GunUI"):Clone()
		UI.Parent = Players.LocalPlayer.PlayerGui
	end

	UI.Frame.Ammo.Text = ("%s/%s"):format(tool:GetAttribute("Ammo"), gunDetails.MaxAmmo)
	UI.Frame.Gun.Text = tool.Name

	TweenUI:TransparencyFade(UI.Frame.Ammo, false, 1, { Do = "TextTransparency" })
	TweenUI:TransparencyFade(UI.Frame.Bar, false, 1)
	TweenUI:TransparencyFade(UI.Frame.Gun, false, 1, { Do = "TextTransparency" })
end

local function hideUI()
	if not UI then
		UI = Players.LocalPlayer.PlayerGui:FindFirstChild("GunUI")
	end

	TweenUI:TransparencyFade(UI.Frame.Ammo, true, 1, { Do = "TextTransparency" })
	TweenUI:TransparencyFade(UI.Frame.Bar, true, 1)
	TweenUI:TransparencyFade(UI.Frame.Gun, true, 1, { Do = "TextTransparency" })
end

local function updateUI(tool: Tool)
	local gunDetails = GunFunction:InvokeServer("GetGunDetails", tool)

	UI.Frame.Ammo.Text = ("%s/%s"):format(tool:GetAttribute("Ammo"), gunDetails.MaxAmmo)
	UI.Frame.Gun.Text = tool.Name
end

local function doReload(tool: Tool)
	if reloading then
		return
	end

	local gunDetails = GunFunction:InvokeServer("GetGunDetails", tool)
	local sound = tool.Handle:FindFirstChild("Reload")

	if tool:GetAttribute("Ammo") == gunDetails.MaxAmmo then
		return
	end

	reloading = true
	if sound then
		sound:Play()
	end

	reload:Play()
	reload:AdjustSpeed(gunDetails.ReloadTime)

	UI.Frame.Ammo.Text = "Reloading..."

	task.wait(gunDetails.ReloadTime)
	GunRemote:FireServer("Reload", nil, tool)
	updateUI(tool)
	reloading = false
end

local function setCursor(state: boolean)
	local mouse = Players.LocalPlayer:GetMouse()
	if state then
		mouse.Icon = cursor
	else
		mouse.Icon = ""
	end
end

local function setLight(tool: Tool)
	if not click then
		click = Instance.new("Sound", tool.Muzzle)
		click.Name = "ClickSound"
		click.SoundId = clickSound
	end

	click:Play()
	light = not light
	tool.Muzzle.Light.Enabled = light
end

local function indicateDamage(char: Model, damage: number)
	local highlight: Highlight = ReplicatedStorage:FindFirstChild("DamageHighlight"):Clone()
	local indicator: BillboardGui = ReplicatedStorage:FindFirstChild("DamageUI"):Clone()

	local playerIndicator = Players.LocalPlayer.PlayerGui:FindFirstChild("DamageStats")
	playerIndicator.Frame.Damage.Text = damage + tonumber(playerIndicator.Frame.Damage.Text)

	if not highlight or not indicator then
		return warn("unable to get requested assets")
	end

	highlight:AddTag("Damage")
	indicator:AddTag("Damage")

	if char:FindFirstChild("DamageUI") and char:FindFirstChild("DamageHighlight") then
		indicator = char:FindFirstChild("DamageUI")
		indicator.Number.Text = tonumber(indicator.Number.Text) + damage

		highlight = char:FindFirstChild("DamageHighlight")
		TweenUI:HighlightFade(highlight, 0.55, 0.8)
		TweenUI:TransparencyFade(indicator.Number, false, 0.8, { Do = "TextTransparency" })
		return
	end

	highlight.Parent = char

	TweenUI:HighlightFade(highlight, 0.55, 0.8)

	indicator.Parent = char
	indicator.Adornee = char.HumanoidRootPart
	indicator.Number.Text = damage

	TweenUI:TransparencyFade(indicator.Number, false, 0.8, { Do = "TextTransparency" })
end

local function initializeGuns(character)
	for _, tool: Tool in Players.LocalPlayer.Backpack:GetChildren() do
		if tool:HasTag("OwnedGun") then
			if initializedGuns[tool] then
				continue
			end

			tool.Equipped:Connect(function(mouse)
				showAndSetupUi(tool)
				setCursor(true)
				local animator: Animator = character.Humanoid.Animator
				fire = animator:LoadAnimation(tool.Animations.Fire)
				equip = animator:LoadAnimation(tool.Animations.Equipt)
				reload = animator:LoadAnimation(tool.Animations.Reload)

				animationCache[#animationCache + 1] = equip
				animationCache[#animationCache + 1] = fire
				animationCache[#animationCache + 1] = reload

				local gunDetails = GunFunction:InvokeServer("GetGunDetails", tool)

				equip.Priority = Enum.AnimationPriority.Action
				equip:Play()

				connections["EquipConnection"] = equip.Stopped:Connect(function()
					equip:AdjustWeight(1)

					connections["Inputs"] = UserInputService.InputBegan:Connect(function(input, gpe)
						if not gpe and character:FindFirstChild(tool.Name) then
							if input.KeyCode == Enum.KeyCode.F then
								setLight(tool)
								return
							elseif input.KeyCode == Enum.KeyCode.R then
								doReload(tool)
							elseif input.KeyCode == Enum.KeyCode.V then
								if canSwitchFirerate then
									if not firerateSwitch then
										firerateSwitch = Instance.new("Sound", tool.Muzzle)
										firerateSwitch.Name = "ClickSound"
										firerateSwitch.SoundId = switchFirerateSound
									end

									firerateSwitch:Play()
									if firerate == "Automatic" then
										firerate = "Single"
									else
										firerate = "Automatic"
									end
								end
							end
						end
					end)

					connections["Fire"] = mouse.Button1Down:Connect(function()
						if not reloading and not fired then
							fired = true
							if not fire.IsPlaying then
								if firerate == "Automatic" then
									fire.Looped = true
									fire:Play()
									fire:AdjustSpeed(gunDetails.AnimationFireSpeed or 4)
								else
									fire.Looped = false
									fire:Play()
								end
							end
							GunRemote:FireServer("Fire", mouse.Hit.Position, tool, firerate)
							task.wait(gunDetails.RestTime or 0)
							fired = false
						end
					end)

					connections["Stop"] = mouse.Button1Up:Connect(function()
						GunRemote:FireServer("Stop", nil, tool)

						if fire.IsPlaying then
							fire.Looped = false
							fire:Stop()
						end

						if not hasShownIndicator then
							hasShownIndicator = task.delay(4, function()
								for _, inst in CollectionService:GetTagged("Damage") do
									if inst:IsA("Highlight") then
										TweenUI:HighlightFade(inst, 1, 0.8)
										task.wait(0.8)
										inst:Destroy()
									else
										if inst:FindFirstChild("Number") then
											TweenUI:TransparencyFade(
												inst.Number,
												true,
												0.8,
												{ Do = "TextTransparency" }
											)
											task.delay(0.8, function()
												inst:Destroy()
											end)
										end
									end
								end
							end)
						else
							task.cancel(hasShownIndicator)
							hasShownIndicator = task.delay(4, function()
								for _, inst in CollectionService:GetTagged("Damage") do
									if inst:IsA("Highlight") then
										TweenUI:HighlightFade(inst, 1, 0.8)
										task.wait(0.8)
										inst:Destroy()
									else
										if inst:FindFirstChild("Number") then
											TweenUI:TransparencyFade(
												inst.Number,
												true,
												0.8,
												{ Do = "TextTransparency" }
											)
											task.delay(0.8, function()
												inst:Destroy()
											end)
										end
									end
								end
							end)
						end
					end)

					connections["Ammo"] = tool:GetAttributeChangedSignal("Ammo"):Connect(function()
						updateUI(tool)
					end)
				end)
			end)

			tool.Unequipped:Connect(function()
				for _, conn in connections do
					conn:Disconnect()
				end

				for i, anim in animationCache do
					anim:Stop()
					anim:AdjustWeight(0)
					animationCache[i] = nil
				end

				fire:Stop()
				reload:Stop()

				hideUI()
				setCursor(false)
				ContextActionService:UnbindAction("Reload")
				ContextActionService:UnbindAction("Light")
				GunRemote:FireServer("Stop", nil, tool)
			end)

			initializedGuns[tool] = true
		end
	end
end

function public:ChangeCursor(img)
	cursor = img == "0" and defaultcursor or ("rbxassetid://%s"):format(img)
	warn("changed cursor to", img)
end

function public:Init()
	GunFunction.OnClientInvoke = function(request, ...)
		local args = { ... }
		if request == "MouseLocation" then
			return Players.LocalPlayer:GetMouse().Hit.Position
		elseif request == "CameraLocation" then
			return workspace.CurrentCamera.CFrame.Position
		elseif request == "DamageIndicator" then
			return indicateDamage(args[1], args[2])
		end
	end

	Players.LocalPlayer.CharacterAdded:Connect(function(character)
		initializeGuns(Players.LocalPlayer.Character)

		Players.LocalPlayer.Backpack.ChildAdded:Connect(function(child)
			initializeGuns(Players.LocalPlayer.Character)
		end)
	end)

	Players.LocalPlayer.CharacterRemoving:Connect(function(character)
		for tool, bool in initializedGuns do
			initializedGuns[tool] = nil
		end
	end)
end

function public:Start() end

return public
