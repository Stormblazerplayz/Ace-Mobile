-- @title Health bar over enemies
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script in ServerScriptService. Every NPC (any model with a Humanoid that is not a player) gets a bar.
-- @keywords enemy health bar, npc hp bar, overhead health, floating health bar, mob health
-- @about Adds a small floating health bar with the name above every NPC's head that shrinks as it takes damage.

local Players = game:GetService("Players")

local function addBar(humanoid)
	local model = humanoid.Parent
	if not model or Players:GetPlayerFromCharacter(model) then
		return -- players have their own health bar
	end
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if not head or head:FindFirstChild("HealthBar") then
		return
	end
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff -- hide the default one

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromOffset(120, 30)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.MaxDistance = 80
	billboard.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = model.Name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = billboard

	local back = Instance.new("Frame")
	back.Position = UDim2.fromScale(0, 0.6)
	back.Size = UDim2.fromScale(1, 0.35)
	back.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
	back.Parent = billboard
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local function update()
		fill.Size = UDim2.fromScale(math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 1)
	end
	humanoid.HealthChanged:Connect(update)
	update()
end

for _, object in ipairs(workspace:GetDescendants()) do
	if object:IsA("Humanoid") then
		task.spawn(addBar, object)
	end
end
workspace.DescendantAdded:Connect(function(object)
	if object:IsA("Humanoid") then
		task.wait() -- let the rest of the model arrive
		addBar(object)
	end
end)
