-- @title Fireball spell
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a wand or staff Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords fireball, magic spell, wizard wand, cast fireball, fire magic, staff attack
-- @about Casts a glowing fireball that flies toward where you click and sets enemies on fire for a few seconds.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local SPEED = 70
local HIT_DAMAGE = 20
local BURN_DAMAGE = 5 -- per second
local BURN_TIME = 4
local COOLDOWN = 1.5
local MAX_DISTANCE = 250

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local lastCast = 0

local function burn(humanoid, caster)
	local root = humanoid.Parent:FindFirstChild("HumanoidRootPart")
	if not root or root:FindFirstChild("Burning") then
		return
	end
	local fire = Instance.new("Fire")
	fire.Name = "Burning"
	fire.Parent = root
	for _ = 1, BURN_TIME do
		task.wait(1)
		if humanoid.Health <= 0 then
			break
		end
		humanoid:TakeDamage(BURN_DAMAGE)
	end
	fire:Destroy()
end

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	if Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" then
		return
	end
	if os.clock() - lastCast < COOLDOWN then
		return
	end
	lastCast = os.clock()

	local position = handle.Position
	if (target - position).Magnitude < 1 then
		return
	end
	local direction = (target - position).Unit
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2, 2, 2)
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 120, 30)
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.Position = position
	local flame = Instance.new("Fire")
	flame.Size = 4
	flame.Parent = ball
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 50)
	light.Range = 14
	light.Parent = ball
	ball.Parent = workspace

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, ball }
	local travelled = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		local step = direction * SPEED * deltaTime
		local result = workspace:Raycast(position, step, params)
		travelled += step.Magnitude
		if result or travelled > MAX_DISTANCE then
			connection:Disconnect()
			ball:Destroy()
			local model = result and result.Instance:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			local victim = model and Players:GetPlayerFromCharacter(model)
			local teammate = victim and victim.Team and victim.Team == player.Team and not player.Neutral
			if humanoid and not teammate then
				local tag = Instance.new("ObjectValue")
				tag.Name = "creator"
				tag.Value = player
				tag.Parent = humanoid
				Debris:AddItem(tag, BURN_TIME + 1)
				humanoid:TakeDamage(HIT_DAMAGE)
				task.spawn(burn, humanoid, player)
			end
			return
		end
		position += step
		ball.Position = position
	end)
end)
