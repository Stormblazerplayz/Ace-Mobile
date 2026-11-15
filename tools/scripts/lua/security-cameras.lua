-- @title Security camera monitor
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Add a Part named SecurityMonitor, and a Folder named SecurityCams with anchored Parts pointing their front face where each camera looks.
-- @keywords security cameras, cctv, camera monitor, watch rooms, surveillance screens
-- @about Use the monitor to look through the security cameras around your map, switching with Next and leaving with Exit.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local monitor = workspace:WaitForChild("SecurityMonitor")
local camsFolder = workspace:WaitForChild("SecurityCams")

-- A prompt made in a LocalScript only shows for this player
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Watch cameras"
prompt.Parent = monitor

local gui = Instance.new("ScreenGui")
gui.Name = "SecurityCams"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(20, 20)
title.Size = UDim2.fromOffset(260, 36)
title.BackgroundColor3 = Color3.new(0, 0, 0)
title.TextColor3 = Color3.fromRGB(120, 255, 120)
title.Font = Enum.Font.Code
title.TextScaled = true
title.Parent = gui

local function makeButton(text, x)
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, x, 1, -20)
	button.Size = UDim2.fromOffset(120, 44)
	button.Text = text
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = gui
	return button
end
local nextButton = makeButton("Next", -70)
local exitButton = makeButton("Exit", 70)

local index = 1
local function showCam()
	local cams = camsFolder:GetChildren()
	if #cams == 0 then
		return
	end
	index = (index - 1) % #cams + 1
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cams[index].CFrame
	title.Text = "CAM " .. index .. ": " .. cams[index].Name
end

prompt.Triggered:Connect(function()
	gui.Enabled = true
	showCam()
end)
nextButton.Activated:Connect(function()
	index += 1
	showCam()
end)
exitButton.Activated:Connect(function()
	gui.Enabled = false
	camera.CameraType = Enum.CameraType.Custom
end)
