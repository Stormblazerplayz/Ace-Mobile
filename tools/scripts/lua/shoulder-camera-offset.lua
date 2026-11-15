-- @title Over the shoulder camera
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords over the shoulder, shoulder camera, camera offset, third person shooter view, swap shoulder
-- @about Moves the camera over your right shoulder like a third person shooter; press Q to swap to the left shoulder.

local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

-- Settings: change these!
local SIDE = 2 -- studs to the side
local UP = 0.5

local humanoid = script.Parent:WaitForChild("Humanoid")
local right = true

local function apply()
	local offset = Vector3.new(right and SIDE or -SIDE, UP, 0)
	-- CameraOffset moves the camera without changing where the character is
	TweenService:Create(humanoid, TweenInfo.new(0.25), { CameraOffset = offset }):Play()
end

ContextActionService:BindAction("SwapShoulder", function(_, state)
	if state == Enum.UserInputState.Begin then
		right = not right
		apply()
	end
	return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.Q)
ContextActionService:SetTitle("SwapShoulder", "Swap")

humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("SwapShoulder")
end)

apply()
