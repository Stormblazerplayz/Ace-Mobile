-- @title Crosshair in the middle
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords crosshair, aim dot, reticle, center aim, shooter crosshair
-- @about Draws a small plus-shaped crosshair in the center of the screen that only shows while you hold a tool.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Crosshair"
gui.IgnoreGuiInset = true -- so the middle is the true middle of the screen
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local function line(width, height)
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(0.5, 0.5)
	bar.Size = UDim2.fromOffset(width, height)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Parent = bar
	bar.Parent = gui
end
line(18, 2)
line(2, 18)

-- Show it only while a tool is equipped
local function watch(character)
	local function refresh()
		gui.Enabled = character:FindFirstChildOfClass("Tool") ~= nil
	end
	character.ChildAdded:Connect(refresh)
	character.ChildRemoved:Connect(refresh)
	refresh()
end
player.CharacterAdded:Connect(watch)
if player.Character then
	watch(player.Character)
end
