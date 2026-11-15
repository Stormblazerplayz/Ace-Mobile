-- @title Rocket launcher
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords rocket launcher, rocket, bazooka, explosive weapon, rpg
-- @about Fires a rocket that flies straight to where you clicked and explodes, hurting everyone nearby.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local SPEED = 80 -- studs per second
local MAX_DISTANCE = 400
local BLAST_RADIUS = 10
local MAX_DAMAGE = 60 -- damage right in the middle (less further away)
local COOLDOWN = 2

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local lastShot = 0

local function explode(position, shooter)
	local boom = Instance.new("Explosion")
	boom.Position = position
	boom.BlastRadius = BLAST_RADIUS
	boom.DestroyJointRadiusPercent = 0 -- we do our own damage below
	local hurt = {}
	boom.Hit:Connect(function(part, distance)
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if not humanoid or hurt[humanoid] then
			return
		end
		hurt[humanoid] = true
		local victim = Players:GetPlayerFromCharacter(model)
		if victim and victim ~= shooter and victim.Team and victim.Team == shooter.Team and not shooter.Neutral then
			return -- teammates are safe
		end
		local tag = Instance.new("ObjectValue")
		tag.Name = "creator"
		tag.Value = shooter
		tag.Parent = humanoid
		Debris:AddItem(tag, 2)
		humanoid:TakeDamage(MAX_DAMAGE * (1 - distance / BLAST_RADIUS))
	end)
	boom.Parent = workspace
end

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	if Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" then
		return
	end
	if os.clock() - lastShot < COOLDOWN then
		return
	end
	lastShot = os.clock()

	local position = handle.Position
	if (target - position).Magnitude < 1 then
		return
	end
	local direction = (target - position).Unit
	local rocket = Instance.new("Part")
	rocket.Size = Vector3.new(0.6, 0.6, 2.5)
	rocket.Anchored = true
	rocket.CanCollide = false
	rocket.CanQuery = false
	rocket.Color = Color3.fromRGB(90, 90, 90)
	rocket.CFrame = CFrame.lookAt(position, position + direction)
	local fire = Instance.new("Fire")
	fire.Size = 2
	fire.Parent = rocket
	rocket.Parent = workspace

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, rocket }
	local travelled = 0

	-- Move the rocket a little each frame and check if it hit something on the way
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		local step = direction * SPEED * deltaTime
		local result = workspace:Raycast(position, step, params)
		travelled += step.Magnitude
		if result or travelled > MAX_DISTANCE then
			connection:Disconnect()
			rocket:Destroy()
			explode(result and result.Position or position, player)
			return
		end
		position += step
		rocket.CFrame = CFrame.lookAt(position, position + direction)
	end)
end)
