-- @title Slide while running
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords slide, slide ability, power slide, slide under things, run and slide
-- @about While running, press Left Ctrl (or the Slide button) to slide along the ground fast and low.

local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local SLIDE_SPEED = 60
local SLIDE_TIME = 0.6 -- seconds
local COOLDOWN = 1.2

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local lastSlide = 0

local function slide(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	-- Must be moving and on the ground
	if humanoid.MoveDirection.Magnitude < 0.1 or humanoid.FloorMaterial == Enum.Material.Air then
		return Enum.ContextActionResult.Pass
	end
	if os.clock() - lastSlide < COOLDOWN then
		return Enum.ContextActionResult.Sink
	end
	lastSlide = os.clock()

	local direction = humanoid.MoveDirection.Unit
	humanoid.CameraOffset = Vector3.new(0, -1.5, 0) -- camera goes low
	-- task.spawn runs the slide on its own, so the key handler can finish straight away
	task.spawn(function()
		local endTime = os.clock() + SLIDE_TIME
		while os.clock() < endTime and humanoid.Health > 0 do
			-- Slow down a little as the slide goes on
			local left = (endTime - os.clock()) / SLIDE_TIME
			local y = root.AssemblyLinearVelocity.Y
			root.AssemblyLinearVelocity = direction * (SLIDE_SPEED * left + humanoid.WalkSpeed) + Vector3.new(0, y, 0)
			task.wait()
		end
		TweenService:Create(humanoid, TweenInfo.new(0.2), { CameraOffset = Vector3.zero }):Play()
	end)
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("Slide", slide, true, Enum.KeyCode.LeftControl)
ContextActionService:SetTitle("Slide", "Slide")
humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("Slide")
end)
