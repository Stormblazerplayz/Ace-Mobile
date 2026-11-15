-- @title Button that opens a door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside a Model in Workspace that holds two parts named Button and Door.
-- @keywords button opens door, press button, click button door, switch opens door, button and door
-- @about Clicking, tapping or stepping on the button opens the door for a few seconds.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local OPEN_TIME = 5 -- seconds the door stays open
local PRESSED_COLOR = Color3.fromRGB(0, 255, 0) -- button color while the door is open

local model = script.Parent
local button = model:WaitForChild("Button")
local door = model:WaitForChild("Door")

-- Add a ClickDetector so the button can be clicked or tapped
local clickDetector = button:FindFirstChildOfClass("ClickDetector") or Instance.new("ClickDetector")
clickDetector.Parent = button

local buttonColor = button.Color
local doorTransparency = door.Transparency
local isOpen = false

local function openDoor()
	if isOpen then
		return
	end
	isOpen = true
	button.Color = PRESSED_COLOR
	door.CanCollide = false
	door.Transparency = 0.8

	task.wait(OPEN_TIME)

	door.CanCollide = true
	door.Transparency = doorTransparency
	button.Color = buttonColor
	isOpen = false
end

-- Click or tap the button
clickDetector.MouseClick:Connect(openDoor)

-- Or step on the button
button.Touched:Connect(function(hit)
	if Players:GetPlayerFromCharacter(hit.Parent) then
		openDoor()
	end
end)
