-- @title Floating damage numbers
-- @category Tools and combat
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords damage numbers, floating damage text, hit numbers, damage popup, show damage dealt
-- @about Whenever a player or NPC loses health, a red number pops up above them and floats away.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local watched = {}

local function popNumber(head, amount)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(80, 40)
	billboard.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 100
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "-" .. math.floor(amount + 0.5)
	label.TextColor3 = Color3.fromRGB(255, 70, 60)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = billboard
	billboard.Parent = head

	-- Float up and fade out
	local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(billboard, info, { StudsOffset = billboard.StudsOffset + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(billboard, 0.9)
end

local function watch(humanoid)
	if watched[humanoid] then
		return
	end
	watched[humanoid] = true
	local last = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		local lost = last - health
		last = health
		local head = humanoid.Parent and humanoid.Parent:FindFirstChild("Head")
		if lost >= 1 and head then
			popNumber(head, lost)
		end
	end)
	humanoid.AncestryChanged:Connect(function()
		if not humanoid:IsDescendantOf(workspace) then
			watched[humanoid] = nil
		end
	end)
end

-- Watch every humanoid in the game, now and later
for _, thing in ipairs(workspace:GetDescendants()) do
	if thing:IsA("Humanoid") then
		watch(thing)
	end
end
workspace.DescendantAdded:Connect(function(thing)
	if thing:IsA("Humanoid") then
		watch(thing)
	end
end)
