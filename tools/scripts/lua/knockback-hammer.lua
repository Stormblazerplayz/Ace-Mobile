-- @title Knockback hammer
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part (the hammer) and put the Tool in StarterPack.
-- @keywords knockback hammer, ban hammer, smash and launch, bonk, send players flying
-- @about Smash the ground in front of you to launch every nearby player into the air with a big BONK.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local RADIUS = 8
local LAUNCH_UP = 70
local LAUNCH_AWAY = 50
local DAMAGE = 5
local COOLDOWN = 2

local tool = script.Parent
local lastSmash = 0

tool.Activated:Connect(function()
	local character = tool.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or os.clock() - lastSmash < COOLDOWN then
		return
	end
	lastSmash = os.clock()

	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool

	local center = root.Position + root.CFrame.LookVector * (RADIUS / 2)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local launched = {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(center, RADIUS, params)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		local theirRoot = model and model:FindFirstChild("HumanoidRootPart")
		if humanoid and theirRoot and not launched[model] then
			launched[model] = true
			local away = (theirRoot.Position - root.Position) * Vector3.new(1, 0, 1)
			if away.Magnitude < 0.1 then
				away = root.CFrame.LookVector
			end
			-- Ragdoll them for a moment so they tumble through the air
			humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			theirRoot.AssemblyLinearVelocity = away.Unit * LAUNCH_AWAY + Vector3.new(0, LAUNCH_UP, 0)
			humanoid:TakeDamage(DAMAGE)
		end
	end
end)
