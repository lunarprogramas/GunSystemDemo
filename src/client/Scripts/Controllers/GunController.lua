local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local public = {}

local import = require(ReplicatedStorage.Shared.import)
local Network = import("Shared/Network")
local TweenUI = import("Shared/TweenUI")

local GunRemote = Network.GetRemoteEvent("GunRE")
local GunFunction: RemoteFunction = Network.GetRemoteFunction("GunRF")

local con1, con2, con3, reloading, fire, equip, reload
local UI

local cursor = "rbxassetid://16717300045"

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
	local gunDetails = GunFunction:InvokeServer("GetGunDetails", tool)
	local sound = tool.Handle:FindFirstChild("Reload")

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

function public:Init()
	GunFunction.OnClientInvoke = function(request)
		if request == "MouseLocation" then
			return Players.LocalPlayer:GetMouse().Hit.Position
		elseif request == "CameraLocation" then
			return workspace.CurrentCamera.CFrame.Position
		end
	end

	Players.LocalPlayer.CharacterAdded:Connect(function(character)
		for _, tool: Tool in Players.LocalPlayer.Backpack:GetChildren() do
			if tool:HasTag("OwnedGun") then
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
						ContextActionService:BindAction("Reload", function(gpe)
							if gpe and character:FindFirstChild(tool.Name) then
								doReload(tool)
							end
						end, false, Enum.KeyCode.R)

						ContextActionService:BindAction("Light", function(gpe)
							if gpe and character:FindFirstChild(tool.Name) then
								tool.Muzzle.Light.Enabled = not tool.Muzzle.Light.Enabled
								return
							end
						end, false, Enum.KeyCode.F)

						con1 = mouse.Button1Down:Connect(function()
							if not reloading then
								fire:Play()
								GunRemote:FireServer("Fire", mouse.Hit.Position, tool)
							end
						end)

						con2 = mouse.Button1Up:Connect(function()
							GunRemote:FireServer("Stop", nil, tool)
						end)

						con3 = tool:GetAttributeChangedSignal("Ammo"):Connect(function()
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
					con1:Disconnect()
					con2:Disconnect()
					con3:Disconnect()
				end)
			end
		end
	end)
end

function public:Start() end

return public
