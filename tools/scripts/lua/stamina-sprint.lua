-- @title Sprint with a stamina bar
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts (do not also use the Sprint button script).
-- @keywords stamina, stamina bar, run out of energy, sprint stamina, energy bar, tired when running
-- @about Hold Shift to run, but running uses up a stamina bar that refills when you walk.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local WALK_SPEED = 16
local RUN_SPEED = 28
local MAX_STAMINA = 100
local DRAIN_PER_SECOND = 25
local REFILL_PER_SECOND = 15

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local stamina = MAX_STAMINA
local wantsToRun = false

-- Build a little bar at the bottom of the screen
local gui = Instance.new("ScreenGui")
gui.Name = "StaminaGui"
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local back = Instance.new("Frame")
back.AnchorPoint = Vector2.new(0.5, 1)
back.Position = UDim2.new(0.5, 0, 1, -20)
back.Size = UDim2.fromOffset(240, 14)
back.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
back.Parent = gui
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
fill.BorderSizePixel = 0
fill.Parent = back

ContextActionService:BindAction("Run", function(_, state)
	wantsToRun = state == Enum.UserInputState.Begin
	return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.LeftShift)
ContextActionService:SetTitle("Run", "Run")

RunService.Heartbeat:Connect(function(deltaTime)
	local moving = humanoid.MoveDirection.Magnitude > 0
	local running = wantsToRun and moving and stamina > 0
	if running then
		stamina = math.max(stamina - DRAIN_PER_SECOND * deltaTime, 0)
	else
		stamina = math.min(stamina + REFILL_PER_SECOND * deltaTime, MAX_STAMINA)
	end
	humanoid.WalkSpeed = running and RUN_SPEED or WALK_SPEED
	fill.Size = UDim2.fromScale(stamina / MAX_STAMINA, 1)
end)

humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("Run")
	gui:Destroy()
end)
