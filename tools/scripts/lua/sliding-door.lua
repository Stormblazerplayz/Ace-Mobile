-- @title Sliding door with E prompt
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored door Part.
-- @keywords sliding door, slide open door, press e door, proximity prompt door, sci fi door
-- @about Press E near the door to make it slide sideways out of the way; it slides back shut after a few seconds.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local SLIDE_TIME = 0.6
local STAY_OPEN = 4 -- seconds before it closes by itself

local door = script.Parent
door.Anchored = true
local closed = door.CFrame
-- Slide along the door's own X direction by its full width
local open = closed * CFrame.new(door.Size.X, 0, 0)

local info = TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local openTween = TweenService:Create(door, info, { CFrame = open })
local closeTween = TweenService:Create(door, info, { CFrame = closed })

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Open"
prompt.ObjectText = "Door"
prompt.MaxActivationDistance = 10
prompt.Parent = door

local isOpen = false
local openCount = 0

prompt.Triggered:Connect(function()
	if isOpen then
		return
	end
	isOpen = true
	openCount += 1
	local myOpen = openCount
	prompt.Enabled = false
	openTween:Play()
	task.wait(STAY_OPEN)
	if myOpen == openCount then
		closeTween:Play()
		closeTween.Completed:Wait()
		isOpen = false
		prompt.Enabled = true
	end
end)
