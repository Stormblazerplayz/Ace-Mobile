-- @title Double jump
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords double jump, jump twice, jump in the air, air jump, extra jump
-- @about Lets players jump a second time while they are in the air (works with the jump button on phones and iPads too).

local UserInputService = game:GetService("UserInputService")

-- Settings: change these numbers!
local DOUBLE_JUMP_POWER = 50 -- how high the second jump goes
local DELAY = 0.2 -- seconds after leaving the ground before you can jump again

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local leftGroundAt = nil -- when we left the ground
local usedDoubleJump = false

-- Keep track of when we are on the ground or in the air
humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Landed
		or newState == Enum.HumanoidStateType.Running
		or newState == Enum.HumanoidStateType.Climbing
		or newState == Enum.HumanoidStateType.Swimming then
		leftGroundAt = nil
		usedDoubleJump = false
	elseif newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
		if not leftGroundAt then
			leftGroundAt = os.clock()
		end
	end
end)

-- When the player presses jump in the air, jump again (only once!)
UserInputService.JumpRequest:Connect(function()
	if usedDoubleJump or not leftGroundAt then
		return
	end
	if os.clock() - leftGroundAt < DELAY then
		return
	end
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end

	usedDoubleJump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	local velocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, DOUBLE_JUMP_POWER, velocity.Z)
end)
