-- @title Swinging door on hinges
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored door Part (the door is wide along X; the hinge is on the -X side).
-- @keywords swinging door, hinged door, door swings open, house door, open and close door
-- @about Press E to swing the door open like a real house door, and press E again to close it.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local OPEN_ANGLE = 90 -- degrees (use -90 to swing the other way)
local SWING_TIME = 0.5

local door = script.Parent
door.Anchored = true
local closed = door.CFrame
-- Turn around the hinge edge instead of the middle of the door
local hinge = closed * CFrame.new(-door.Size.X / 2, 0, 0)
local open = hinge * CFrame.Angles(0, math.rad(OPEN_ANGLE), 0) * CFrame.new(door.Size.X / 2, 0, 0)

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Open"
prompt.ObjectText = "Door"
prompt.Parent = door

local isOpen = false
prompt.Triggered:Connect(function()
	isOpen = not isOpen
	prompt.ActionText = isOpen and "Close" or "Open"
	local goal = isOpen and open or closed
	TweenService:Create(door, TweenInfo.new(SWING_TIME, Enum.EasingStyle.Sine), { CFrame = goal }):Play()
end)
