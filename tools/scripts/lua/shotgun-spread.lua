-- @title Shotgun with spread
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords shotgun, pellets, spread shot, close range gun, scatter gun
-- @about Fires many pellets at once in a cone, so it is strong up close and weak far away.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local PELLETS = 8
local DAMAGE_PER_PELLET = 8
local SPREAD_DEGREES = 6
local RANGE = 80
local COOLDOWN = 0.9

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool

local lastShot = 0

local function tracer(from, to)
	local line = Instance.new("Part")
	line.Anchored = true
	line.CanCollide = false
	line.CanQuery = false
	line.CanTouch = false
	line.Material = Enum.Material.Neon
	line.Color = Color3.fromRGB(255, 200, 100)
	line.Size = Vector3.new(0.06, 0.06, (to - from).Magnitude)
	line.CFrame = CFrame.lookAt((from + to) / 2, to)
	line.Parent = workspace
	Debris:AddItem(line, 0.05)
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

	local origin = handle.Position
	if (target - origin).Magnitude < 0.1 then
		return
	end
	local aim = CFrame.lookAt(origin, target)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local damageDone = {} -- add up pellets per humanoid
	for _ = 1, PELLETS do
		-- Tilt each pellet a little bit in a random direction
		local spread = aim * CFrame.Angles(
			math.rad((math.random() - 0.5) * 2 * SPREAD_DEGREES),
			math.rad((math.random() - 0.5) * 2 * SPREAD_DEGREES),
			0
		)
		local direction = spread.LookVector * RANGE
		local result = workspace:Raycast(origin, direction, params)
		tracer(origin, result and result.Position or origin + direction)
		local model = result and result.Instance:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			damageDone[humanoid] = (damageDone[humanoid] or 0) + DAMAGE_PER_PELLET
		end
	end

	for humanoid, damage in pairs(damageDone) do
		local victim = Players:GetPlayerFromCharacter(humanoid.Parent)
		local teammate = victim and victim.Team and victim.Team == player.Team and not player.Neutral
		if not teammate and humanoid.Health > 0 then
			local tag = Instance.new("ObjectValue")
			tag.Name = "creator"
			tag.Value = player
			tag.Parent = humanoid
			Debris:AddItem(tag, 2)
			humanoid:TakeDamage(damage)
		end
	end
end)
