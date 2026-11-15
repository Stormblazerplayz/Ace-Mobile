-- @title Compass bar
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords compass, north south east west, direction bar, heading display, navigation compass
-- @about Shows a compass strip at the top of the screen with N, E, S and W sliding as you turn the camera.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "Compass"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local strip = Instance.new("Frame")
strip.AnchorPoint = Vector2.new(0.5, 0)
strip.Position = UDim2.new(0.5, 0, 0, 8)
strip.Size = UDim2.fromOffset(360, 30)
strip.BackgroundColor3 = Color3.new(0, 0, 0)
strip.BackgroundTransparency = 0.5
strip.ClipsDescendants = true
strip.Parent = gui

-- In Roblox, "north" is the -Z direction
local letters = { N = 0, E = 90, S = 180, W = 270 }
local labels = {}
for letter, angle in pairs(letters) do
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Size = UDim2.fromOffset(30, 30)
	label.BackgroundTransparency = 1
	label.Text = letter
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = letter == "N" and Color3.fromRGB(255, 80, 80) or Color3.new(1, 1, 1)
	label.Parent = strip
	labels[label] = angle
end

local PIXELS_PER_DEGREE = 2

RunService.RenderStepped:Connect(function()
	local look = camera.CFrame.LookVector
	-- Heading in degrees: 0 means facing north, 90 means east
	local heading = math.deg(math.atan2(look.X, -look.Z)) % 360
	for label, angle in pairs(labels) do
		local diff = (angle - heading + 180) % 360 - 180 -- between -180 and 180
		label.Position = UDim2.new(0.5, diff * PIXELS_PER_DEGREE, 0, 0)
	end
end)
