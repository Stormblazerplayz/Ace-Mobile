-- @title Boomerang
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords boomerang, throw and return, comes back to you, spinning throw, returning weapon
-- @about Throws a spinning boomerang toward your click; it hits enemies on the way out and on the way back to you.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local DISTANCE = 40 -- how far it flies before turning around
local SPEED = 60
local DAMAGE = 15
local HIT_RADIUS = 3

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local flying = false

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if flying or Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" or not root then
		return
	end
	local offset = (target - handle.Position) * Vector3.new(1, 0, 1)
	if offset.Magnitude < 1 then
		return
	end
	flying = true
	handle.Transparency = 1 -- the one in your hand disappears while it flies

	local rang = handle:Clone()
	rang.Anchored = true
	rang.CanCollide = false
	rang.Transparency = 0
	rang.Parent = workspace

	local position = handle.Position
	local direction = offset.Unit
	local travelled = 0
	local returning = false
	local hitOut, hitBack = {}, {}
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, rang }

	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		local step = SPEED * deltaTime
		if not returning then
			position += direction * step
			travelled += step
			returning = travelled >= DISTANCE
		else
			local home = root.Position - position
			if home.Magnitude < 3 or not root.Parent then
				connection:Disconnect()
				rang:Destroy()
				handle.Transparency = 0
				flying = false
				return
			end
			position += home.Unit * math.min(step, home.Magnitude)
		end
		rang.CFrame = CFrame.new(position) * CFrame.Angles(0, os.clock() * 20, 0) -- spin!
		local hitList = returning and hitBack or hitOut
		for _, part in ipairs(workspace:GetPartBoundsInRadius(position, HIT_RADIUS, params)) do
			local model = part:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			if humanoid and not hitList[humanoid] then
				hitList[humanoid] = true
				humanoid:TakeDamage(DAMAGE)
			end
		end
	end)
end)
