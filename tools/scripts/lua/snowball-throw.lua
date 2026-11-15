-- @title Snowball throwing
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part (a white ball), add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords snowball, snowball fight, throw snowballs, slow down hit, winter weapon
-- @about Throws snowballs that splat on whatever they hit; players who get hit are slowed down for a moment.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local THROW_SPEED = 90
local DAMAGE = 5
local SLOW_SPEED = 8
local SLOW_TIME = 2
local COOLDOWN = 0.5

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local lastThrow = 0

local function slowDown(humanoid)
	if humanoid:GetAttribute("Slowed") then
		return
	end
	humanoid:SetAttribute("Slowed", true)
	local normal = humanoid.WalkSpeed
	humanoid.WalkSpeed = SLOW_SPEED
	task.delay(SLOW_TIME, function()
		if humanoid.Parent then
			humanoid.WalkSpeed = normal
			humanoid:SetAttribute("Slowed", nil)
		end
	end)
end

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	if Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" then
		return
	end
	if os.clock() - lastThrow < COOLDOWN then
		return
	end
	lastThrow = os.clock()

	local start = handle.Position + Vector3.new(0, 1, 0)
	if (target - start).Magnitude < 1 then
		return
	end
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(1, 1, 1)
	ball.Color = Color3.new(1, 1, 1)
	ball.Material = Enum.Material.Snow
	ball.CanCollide = false
	ball.Position = start
	ball.Parent = workspace
	ball:SetNetworkOwner(nil)
	-- Aim a bit high because gravity pulls it down
	ball.AssemblyLinearVelocity = (target - start).Unit * THROW_SPEED + Vector3.new(0, 10, 0)
	Debris:AddItem(ball, 5)

	ball.Touched:Connect(function(hit)
		if hit:IsDescendantOf(character) or not ball.Parent then
			return
		end
		local model = hit:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(DAMAGE)
			slowDown(humanoid)
		end
		ball:Destroy() -- splat!
	end)
end)
