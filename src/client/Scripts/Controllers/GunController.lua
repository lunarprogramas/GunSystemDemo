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

local reloading, fire, equip, reload, click
local UI
local light = false

local connections = {}

local initializedGuns = {}

local cursor = "rbxassetid://16717300045"
local clickSound = "rbxassetid://421058925"

local function showAndSetupUi(tool: Tool)
	local gunDetails = GunFunction:InvokeServer("GetGunDetails", tool)

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

				equip:Play()

				equip.Stopped:Connect(function()
					equip:AdjustSpeed(0)
					equip:AdjustWeight(1)

					connections["Inputs"] = UserInputService.InputBegan:Connect(function(input, gpe)
						if not gpe and character:FindFirstChild(tool.Name) then
							if input.KeyCode == Enum.KeyCode.F then
								setLight(tool)
								return
							elseif input.KeyCode == Enum.KeyCode.R then
								doReload(tool)
							end
						end
					end)

					connections["Fire"] = mouse.Button1Down:Connect(function()
						if not reloading then
							fire:Play()
							GunRemote:FireServer("Fire", mouse.Hit.Position, tool)
						end
					end)

					connections["Stop"] = mouse.Button1Up:Connect(function()
						GunRemote:FireServer("Stop", nil, tool)
					end)

					connections["Ammo"] = tool:GetAttributeChangedSignal("Ammo"):Connect(function()
						updateUI(tool)
					end)
				end)
			end)

			tool.Unequipped:Connect(function()
				equip:AdjustSpeed(1)
				equip:AdjustWeight(0)
				hideUI()
				setCursor(false)
				ContextActionService:UnbindAction("Reload")
				ContextActionService:UnbindAction("Light")
				GunRemote:FireServer("Stop", nil, tool)

				for _, conn in connections do
					conn:Disconnect()
				end
			end)

			initializedGuns[tool] = true
		end
	end
end

function public:Init()
	GunFunction.OnClientInvoke = function(request)
		if request == "MouseLocation" then
			return Players.LocalPlayer:GetMouse().Hit.Position
		elseif request == "CameraLocation" then
			return workspace.CurrentCamera.CFrame.Position
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
