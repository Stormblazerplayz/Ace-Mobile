-- @title Tutorial steps
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and change the STEPS list.
-- @keywords tutorial, how to play, new player guide, onboarding tips, step by step help
-- @about Shows new players a short how-to-play box, one tip at a time, with Next and Skip buttons.

local Players = game:GetService("Players")

-- Settings: change these tips!
local STEPS = {
	"Welcome! Use WASD or the joystick to walk around.",
	"Touch the glowing coins to collect money.",
	"Spend coins at the shop to get cool tools.",
	"Have fun and invite your friends!",
}

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Tutorial"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(0.5, 0)
box.Position = UDim2.new(0.5, 0, 0, 100)
box.Size = UDim2.fromOffset(380, 140)
box.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
box.Parent = gui
Instance.new("UICorner", box)

local text = Instance.new("TextLabel")
text.Position = UDim2.fromOffset(12, 10)
text.Size = UDim2.new(1, -24, 0, 80)
text.BackgroundTransparency = 1
text.TextWrapped = true
text.TextScaled = true
text.Font = Enum.Font.GothamMedium
text.TextColor3 = Color3.new(1, 1, 1)
text.Parent = box

local function makeButton(label, xScale, color)
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.Position = UDim2.new(xScale, 0, 0, 96)
	button.Size = UDim2.fromOffset(120, 34)
	button.Text = label
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = color
	button.Parent = box
	return button
end
local nextButton = makeButton("Next", 0.7, Color3.fromRGB(60, 140, 230))
local skipButton = makeButton("Skip", 0.3, Color3.fromRGB(90, 90, 100))

local step = 1
local function show()
	if step > #STEPS then
		gui:Destroy()
		return
	end
	text.Text = STEPS[step]
	nextButton.Text = step == #STEPS and "Done" or "Next"
end
nextButton.Activated:Connect(function()
	step += 1
	show()
end)
skipButton.Activated:Connect(function()
	gui:Destroy()
end)
show()
