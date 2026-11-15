-- @title Parking gate barrier
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside the Anchored barrier arm Part (long along X, with the hinge at the -X end).
-- @keywords parking gate, barrier arm, boom gate, gate lifts up, checkpoint barrier
-- @about Press E to lift the barrier arm; it stays up for a few seconds and then comes back down.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local OPEN_ANGLE = 85 -- degrees it lifts
local STAY_OPEN = 4 -- seconds before it closes

local arm = script.Parent
arm.Anchored = true
local closed = arm.CFrame
-- Spin around the end of the arm, not the middle
local pivot = closed * CFrame.new(-arm.Size.X / 2, 0, 0)
local open = pivot * CFrame.Angles(0, 0, math.rad(OPEN_ANGLE)) * CFrame.new(arm.Size.X / 2, 0, 0)

local openTween = TweenService:Create(arm, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { CFrame = open })
local closeTween = TweenService:Create(arm, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { CFrame = closed })

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Open gate"
prompt.ObjectText = "Barrier"
prompt.Parent = arm

prompt.Triggered:Connect(function()
	prompt.Enabled = false
	openTween:Play()
	openTween.Completed:Wait()
	task.wait(STAY_OPEN)
	closeTween:Play()
	closeTween.Completed:Wait()
	prompt.Enabled = true
end)
