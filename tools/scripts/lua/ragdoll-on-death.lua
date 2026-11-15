-- @title Ragdoll when you die
-- @category Players
-- @kind Script
-- @where Put this Script in StarterPlayer > StarterCharacterScripts.
-- @keywords ragdoll, ragdoll on death, floppy body, fall over when you die, ragdoll physics
-- @about Instead of breaking into pieces, your character goes floppy like a ragdoll when it dies.

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Do not fall apart, we will make the joints floppy instead
humanoid.BreakJointsOnDeath = false

humanoid.Died:Connect(function()
	for _, joint in ipairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
			-- Make two attachments in the same spots the motor used
			local a0 = Instance.new("Attachment")
			a0.CFrame = joint.C0
			a0.Parent = joint.Part0
			local a1 = Instance.new("Attachment")
			a1.CFrame = joint.C1
			a1.Parent = joint.Part1

			-- A ball socket lets the limb swing around loosely
			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.Parent = joint.Parent

			joint.Enabled = false
		end
	end

	-- Let the limbs bump into the floor instead of sinking through it
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
		end
	end
end)
