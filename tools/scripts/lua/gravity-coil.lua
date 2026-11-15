-- @title Gravity coil
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part and put the Tool in StarterPack.
-- @keywords gravity coil, low gravity tool, float tool, jump really high coil, moon jump
-- @about While you hold the gravity coil, gravity pulls on you much less so you can jump super high.

-- Settings: change this number!
local GRAVITY_LEFT = 0.25 -- 0.25 = only a quarter of normal gravity while holding it

local tool = script.Parent
local force = nil

tool.Equipped:Connect(function()
	local character = tool.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local attachment = root and root:FindFirstChild("RootAttachment")
	if not attachment then
		return
	end
	-- A VectorForce pushes up against gravity on the whole character
	local mass = 0
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			mass += part:GetMass()
		end
	end
	force = Instance.new("VectorForce")
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.Force = Vector3.new(0, mass * workspace.Gravity * (1 - GRAVITY_LEFT), 0)
	force.Parent = root
end)

tool.Unequipped:Connect(function()
	if force then
		force:Destroy()
		force = nil
	end
end)
