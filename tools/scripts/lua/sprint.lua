-- @title Sprint button
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords sprint, run button, hold shift to run, sprint key, sprint button on mobile
-- @about Hold Shift (or the Run button on phones and iPads) to run faster.

local ContextActionService = game:GetService("ContextActionService")

-- Settings: change these numbers!
local SPRINT_SPEED = 28 -- speed while sprinting
local WALK_SPEED = 16 -- normal speed

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Runs when the sprint key or button is pressed or let go
local function onSprint(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		humanoid.WalkSpeed = SPRINT_SPEED
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		humanoid.WalkSpeed = WALK_SPEED
	end
	return Enum.ContextActionResult.Pass
end

-- true = also make a button on touch screens
ContextActionService:BindAction("Sprint", onSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("Sprint", "Run")

-- Remove the button when you die (a new one comes when you respawn)
humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("Sprint")
end)
