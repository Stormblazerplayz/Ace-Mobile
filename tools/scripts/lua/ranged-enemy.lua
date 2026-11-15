-- @title Enemy that throws things
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an enemy NPC Model with a Humanoid, HumanoidRootPart and Head.
-- @keywords ranged enemy, throwing enemy, shooter npc, projectile enemy, enemy that shoots
-- @about The enemy keeps its distance and throws glowing balls at the nearest player it can see.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")
local head = npc:WaitForChild("Head")

-- Settings: change these!
local RANGE = 60
local KEEP_AWAY = 20 -- tries to stay this far from you
local DAMAGE = 12
local THROW_EVERY = 1.5
local BALL_SPEED = 80

root:SetNetworkOwner(nil)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { npc }

-- Find the closest player we can actually see (no wall in the way)
local function findTarget()
	local best, bestDistance = nil, RANGE
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local theirRoot = character and character:FindFirstChild("HumanoidRootPart")
		local theirHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if theirRoot and theirHumanoid and theirHumanoid.Health > 0 then
			local offset = theirRoot.Position - head.Position
			local hit = workspace:Raycast(head.Position, offset, params)
			if offset.Magnitude < bestDistance and hit and hit.Instance:IsDescendantOf(character) then
				best, bestDistance = theirRoot, offset.Magnitude
			end
		end
	end
	return best, bestDistance
end

local function throw(targetPosition)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(1.5, 1.5, 1.5)
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 90, 40)
	ball.CanCollide = false
	ball.CFrame = CFrame.new(head.Position + (targetPosition - head.Position).Unit * 2)
	ball.Parent = workspace
	ball:SetNetworkOwner(nil)
	ball.AssemblyLinearVelocity = (targetPosition - head.Position).Unit * BALL_SPEED
	-- Cancel gravity so it flies straight
	local attachment = Instance.new("Attachment", ball)
	local antiGravity = Instance.new("VectorForce")
	antiGravity.Attachment0 = attachment
	antiGravity.RelativeTo = Enum.ActuatorRelativeTo.World
	antiGravity.Force = Vector3.new(0, ball:GetMass() * workspace.Gravity, 0)
	antiGravity.Parent = ball
	ball.Touched:Connect(function(hit)
		if hit:IsDescendantOf(npc) then
			return
		end
		local victim = hit.Parent:FindFirstChildOfClass("Humanoid")
		if victim then
			victim:TakeDamage(DAMAGE)
		end
		ball:Destroy()
	end)
	Debris:AddItem(ball, 3)
end

while humanoid.Health > 0 do
	local target, distance = findTarget()
	if target then
		-- Back away if too close, walk closer if too far
		local away = (root.Position - target.Position) * Vector3.new(1, 0, 1)
		if distance < KEEP_AWAY and away.Magnitude > 0 then
			humanoid:MoveTo(root.Position + away.Unit * 10)
		elseif distance > KEEP_AWAY + 10 then
			humanoid:MoveTo(target.Position)
		end
		throw(target.Position)
	end
	task.wait(THROW_EVERY)
end
