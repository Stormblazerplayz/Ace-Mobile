-- @title Dash forward
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords dash, dash ability, press q to dash, quick dodge, burst of speed, air dash
-- @about Press Q (or the Dash button on phones) to zoom forward quickly, with a short cooldown.

local ContextActionService = game:GetService("ContextActionService")

-- Settings: change these numbers!
local DASH_SPEED = 90
local COOLDOWN = 1.5 -- seconds between dashes

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local lastDash = 0

local function dash(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if os.clock() - lastDash < COOLDOWN or humanoid.Health <= 0 then
		return Enum.ContextActionResult.Sink
	end
	lastDash = os.clock()

	-- Dash the way we are walking, or the way we face if standing still
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = root.CFrame.LookVector
	end
	direction = Vector3.new(direction.X, 0, direction.Z).Unit
	root.AssemblyLinearVelocity = direction * DASH_SPEED + Vector3.new(0, 5, 0)
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("Dash", dash, true, Enum.KeyCode.Q)
ContextActionService:SetTitle("Dash", "Dash")

humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("Dash")
end)
