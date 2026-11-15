-- @title Place a timed bomb
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part and put the Tool in StarterPack.
-- @keywords timed bomb, place a bomb, ticking bomb, c4, plant explosive
-- @about Click to drop a ticking bomb at your feet; it beeps faster and faster and then explodes.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local FUSE = 4 -- seconds
local DAMAGE = 80
local BLAST_RADIUS = 14
local COOLDOWN = 8

local tool = script.Parent
local lastBomb = 0

tool.Activated:Connect(function()
	local character = tool.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or os.clock() - lastBomb < COOLDOWN then
		return
	end
	lastBomb = os.clock()

	local bomb = Instance.new("Part")
	bomb.Shape = Enum.PartType.Ball
	bomb.Size = Vector3.new(1.5, 1.5, 1.5)
	bomb.Color = Color3.fromRGB(30, 30, 30)
	bomb.Position = root.Position - Vector3.new(0, 2, 0)
	bomb.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 0, 0)
	light.Range = 6
	light.Parent = bomb

	-- Blink faster and faster until it goes off
	local started = os.clock()
	while os.clock() - started < FUSE do
		light.Enabled = not light.Enabled
		bomb.Color = light.Enabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(30, 30, 30)
		local left = FUSE - (os.clock() - started)
		task.wait(math.max(left / 8, 0.05))
	end

	local boom = Instance.new("Explosion")
	boom.Position = bomb.Position
	boom.BlastRadius = BLAST_RADIUS
	boom.DestroyJointRadiusPercent = 0
	local hurt = {}
	boom.Hit:Connect(function(part, distance)
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and not hurt[humanoid] then
			hurt[humanoid] = true
			local tag = Instance.new("ObjectValue")
			tag.Name = "creator"
			tag.Value = player
			tag.Parent = humanoid
			Debris:AddItem(tag, 2)
			humanoid:TakeDamage(DAMAGE * (1 - distance / BLAST_RADIUS))
		end
	end)
	boom.Parent = workspace
	bomb:Destroy()
end)
