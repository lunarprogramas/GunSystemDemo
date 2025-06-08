local TweenUI = {}
local TweenService = game:GetService("TweenService")

-- made by @lunarprogramas (janslan)

function TweenUI:HighlightFade(obj: Highlight, transparent: number, duration: number?)
	local tweenInfo = TweenInfo.new(duration or 0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)

	local function getTransparencyProperties()
		return { FillTransparency = transparent or 1 }
	end

	local properties = getTransparencyProperties()
	if properties then
		local tween = TweenService:Create(obj, tweenInfo, properties)
		tween:Play()
	end
end

function TweenUI:TransparencyFade(ui: Frame, transparent: boolean, duration: number?, options: table?)
	local tweenInfo = TweenInfo.new(duration or 0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)

	local function getTransparencyProperties(asset)
		if options and options.Do then
			if options.Do == "TextTransparency" and asset:IsA("TextLabel") then
				return { TextTransparency = transparent and 1 or 0 }
			end
		else
			if asset:IsA("Frame") then
				return { BackgroundTransparency = transparent and 1 or 0 }
			elseif asset:IsA("TextButton") or asset:IsA("TextLabel") then
				return { BackgroundTransparency = transparent and 1 or 0, TextTransparency = transparent and 1 or 0 }
			elseif
				not asset:IsA("UITextSizeConstraint")
				and not asset:IsA("UIListLayout")
				and not asset:HasTag("IgnoreSetup")
				and not asset:IsA("ModuleScript")
			then
				return { TextTransparency = transparent and 1 or 0 }
			end
		end
		return nil
	end

	if #ui:GetDescendants() > 0 then
		for _, asset in ui:GetDescendants() do
			local properties = getTransparencyProperties(asset)
			if properties then
				local tween = TweenService:Create(asset, tweenInfo, properties)
				tween:Play()
				ui.Visible = true
			end
		end
	end

	local properties = getTransparencyProperties(ui)
	if properties then
		local tween = TweenService:Create(ui, tweenInfo, properties)
		tween:Play()
		ui.Visible = true
	end
end

function TweenUI:FadeColor(ui: Frame, color: boolean, duration: number?)
	if not ui:IsA("TextButton") then
		return
	end

	local tweenInfo = TweenInfo.new(duration or 0, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)

	local tween = TweenService:Create(ui, tweenInfo, { BackgroundColor3 = color })
	tween:Play()
end

return TweenUI
