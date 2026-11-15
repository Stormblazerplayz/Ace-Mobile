-- @title Garage door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored garage door Part.
-- @keywords garage door, roll up door, door goes up, shutter door, warehouse door
-- @about Press E to roll the garage door up into the ceiling, and press E again to bring it down.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local MOVE_TIME = 2

local door = script.Parent
door.Anchored = true
local down = door.CFrame
local up = down + Vector3.new(0, door.Size.Y - 0.5, 0) -- leave a little bit showing

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Open garage"
prompt.ObjectText = "Garage"
prompt.HoldDuration = 0.5
prompt.Parent = door

local isUp = false
prompt.Triggered:Connect(function()
	prompt.Enabled = false
	isUp = not isUp
	local tween = TweenService:Create(door, TweenInfo.new(MOVE_TIME, Enum.EasingStyle.Linear), { CFrame = isUp and up or down })
	tween:Play()
	tween.Completed:Wait()
	prompt.ActionText = isUp and "Close garage" or "Open garage"
	prompt.Enabled = true
end)
