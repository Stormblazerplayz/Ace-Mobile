-- @title Secret bookshelf passage
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the bookshelf Model; put one Part named SecretBook in it (the book players pull).
-- @keywords secret bookshelf, hidden passage, pull the book, secret door, hidden room entrance
-- @about Pull the secret book and the whole bookshelf slides aside to show a hidden passage, then slides back.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local SLIDE_DISTANCE = 8 -- studs the shelf slides sideways
local STAY_OPEN = 8

local shelf = script.Parent
local book = shelf:WaitForChild("SecretBook")
local closed = shelf:GetPivot()
local open = closed * CFrame.new(SLIDE_DISTANCE, 0, 0)

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Pull"
prompt.ObjectText = "Odd-looking book"
prompt.MaxActivationDistance = 6
prompt.Parent = book

-- Models cannot be tweened directly, so we tween a CFrameValue and move the model with it
local function slideTo(goal, seconds)
	local value = Instance.new("CFrameValue")
	value.Value = shelf:GetPivot()
	value.Changed:Connect(function(cf)
		shelf:PivotTo(cf)
	end)
	local tween = TweenService:Create(value, TweenInfo.new(seconds, Enum.EasingStyle.Quad), { Value = goal })
	tween:Play()
	tween.Completed:Wait()
	value:Destroy()
end

prompt.Triggered:Connect(function()
	prompt.Enabled = false
	slideTo(open, 1.5)
	task.wait(STAY_OPEN)
	slideTo(closed, 1.5)
	prompt.Enabled = true
end)
