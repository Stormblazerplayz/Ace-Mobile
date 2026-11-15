-- @title Boss health bar
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts, and put your boss model (with a Humanoid) in Workspace named Boss.
-- @keywords boss health bar, boss hp, big health bar, enemy health top, raid boss bar
-- @about Shows a big health bar with the boss's name at the top of the screen while a model named Boss is in the game.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change this!
local BOSS_NAME = "Boss"

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "BossBar"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local back = Instance.new("Frame")
back.AnchorPoint = Vector2.new(0.5, 0)
back.Position = UDim2.new(0.5, 0, 0, 50)
back.Size = UDim2.new(0.5, 0, 0, 30)
back.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
back.Parent = gui

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
fill.Parent = back

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.TextStrokeTransparency = 0
title.Parent = back

local function track(boss)
	local humanoid = boss:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	gui.Enabled = true
	local function update()
		local fraction = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(fraction, 1) }):Play()
		title.Text = boss.Name .. "  " .. math.ceil(humanoid.Health) .. " / " .. humanoid.MaxHealth
	end
	humanoid.HealthChanged:Connect(update)
	update()
	boss.AncestryChanged:Connect(function()
		if not boss:IsDescendantOf(workspace) then
			gui.Enabled = false
		end
	end)
end

workspace.ChildAdded:Connect(function(child)
	if child.Name == BOSS_NAME then
		track(child)
	end
end)
local existing = workspace:FindFirstChild(BOSS_NAME)
if existing then
	track(existing)
end
