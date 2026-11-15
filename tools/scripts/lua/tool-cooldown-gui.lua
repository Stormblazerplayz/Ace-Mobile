-- @title Tool cooldown bar
-- @category Tools and combat
-- @kind LocalScript
-- @where Put this LocalScript inside any Tool and set COOLDOWN to the same number as the tool's server script.
-- @keywords cooldown bar, ability cooldown, recharge bar, wait timer for tool, cooldown indicator
-- @about Shows a bar under your character that fills back up while the tool is cooling down after you use it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change this to match your tool!
local COOLDOWN = 2

local tool = script.Parent
local player = Players.LocalPlayer
local readyAt = 0

-- A small bar in the middle bottom of the screen
local gui = Instance.new("ScreenGui")
gui.Name = "CooldownBar"
gui.ResetOnSpawn = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local back = Instance.new("Frame")
back.AnchorPoint = Vector2.new(0.5, 1)
back.Position = UDim2.new(0.5, 0, 1, -60)
back.Size = UDim2.fromOffset(160, 10)
back.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
back.Parent = gui
local fill = Instance.new("Frame")
fill.BorderSizePixel = 0
fill.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
fill.Size = UDim2.fromScale(1, 1)
fill.Parent = back

tool.Equipped:Connect(function()
	gui.Enabled = true
end)
tool.Unequipped:Connect(function()
	gui.Enabled = false
end)
tool.Activated:Connect(function()
	if os.clock() >= readyAt then
		readyAt = os.clock() + COOLDOWN
	end
end)

RunService.RenderStepped:Connect(function()
	if not gui.Enabled then
		return
	end
	local left = math.max(readyAt - os.clock(), 0)
	fill.Size = UDim2.fromScale(1 - left / COOLDOWN, 1)
	fill.BackgroundColor3 = left > 0 and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(80, 220, 100)
end)
