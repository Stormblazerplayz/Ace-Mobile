-- @title Position coordinates on screen
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords coordinates, xyz position, where am i, position display, debug position
-- @about Shows your character's X, Y and Z position in the corner, handy for building and finding spots.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Coordinates"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0, 1)
label.Position = UDim2.new(0, 10, 1, -10)
label.Size = UDim2.fromOffset(260, 26)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.BackgroundTransparency = 0.5
label.Font = Enum.Font.Code
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.Parent = gui

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local p = root.Position
		label.Text = string.format("X %d   Y %d   Z %d", p.X, p.Y, p.Z)
	end
end)
