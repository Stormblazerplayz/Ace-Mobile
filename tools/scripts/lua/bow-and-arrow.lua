-- @title Bow and arrow
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part (the bow), add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords bow and arrow, archery, shoot arrows, arrows stick in walls, crossbow
-- @about Shoots arrows that fly in an arc, hurt what they hit and stick into walls for a few seconds.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local ARROW_SPEED = 160
local DAMAGE = 35
local COOLDOWN = 0.8

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local lastShot = 0

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
	local velocity = (target - position).Unit * ARROW_SPEED
	local arrow = Instance.new("Part")
	arrow.Size = Vector3.new(0.2, 0.2, 3)
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.CanQuery = false
	arrow.Color = Color3.fromRGB(120, 85, 50)
	arrow.CFrame = CFrame.lookAt(position, position + velocity)
	arrow.Parent = workspace
	Debris:AddItem(arrow, 8)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, arrow }
	local gravity = Vector3.new(0, -workspace.Gravity * 0.5, 0) -- arrows drop a little

	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		velocity += gravity * deltaTime
		local step = velocity * deltaTime
		local result = workspace:Raycast(position, step, params)
		if result then
			connection:Disconnect()
			-- Stick into whatever we hit
			arrow.CFrame = CFrame.lookAt(result.Position, result.Position + velocity)
			if not result.Instance.Anchored then
				arrow.Anchored = false
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = arrow
				weld.Part1 = result.Instance
				weld.Parent = arrow
				arrow.Massless = true
			end
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			local victim = model and Players:GetPlayerFromCharacter(model)
			local teammate = victim and victim.Team and victim.Team == player.Team and not player.Neutral
			if humanoid and not teammate then
				local tag = Instance.new("ObjectValue")
				tag.Name = "creator"
				tag.Value = player
				tag.Parent = humanoid
				Debris:AddItem(tag, 2)
				humanoid:TakeDamage(DAMAGE)
			end
			return
		end
		position += step
		arrow.CFrame = CFrame.lookAt(position, position + velocity)
	end)
end)
