-- @title Forest generator
-- @category World and effects
-- @kind Script
-- @where Put this Script inside a big flat Anchored Part (the forest area); optional: put tree Models in a Folder named Trees in ServerStorage.
-- @keywords forest generator, scatter trees, random trees, auto place trees, generate a forest
-- @about Places lots of trees at random spots on the ground above the part, each a little bigger or smaller and turned differently.

local ServerStorage = game:GetService("ServerStorage")

-- Settings: change these numbers!
local TREE_COUNT = 60
local MIN_SCALE, MAX_SCALE = 0.8, 1.4

local area = script.Parent
local templates = ServerStorage:FindFirstChild("Trees")

-- A simple tree made of parts, used when you have no tree models
local function simpleTree()
	local tree = Instance.new("Model")
	local trunk = Instance.new("Part")
	trunk.Size = Vector3.new(1.5, 8, 1.5)
	trunk.Position = Vector3.new(0, 4, 0)
	trunk.Color = Color3.fromRGB(110, 75, 45)
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.Parent = tree
	local leaves = Instance.new("Part")
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(7, 7, 7)
	leaves.Position = Vector3.new(0, 9, 0)
	leaves.Color = Color3.fromRGB(60, 140, 60)
	leaves.Material = Enum.Material.Grass
	leaves.Anchored = true
	leaves.Parent = tree
	tree.PrimaryPart = trunk
	return tree
end

local forest = Instance.new("Model")
forest.Name = "Forest"
forest.Parent = workspace

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { forest }

for _ = 1, TREE_COUNT do
	local x = (math.random() - 0.5) * area.Size.X
	local z = (math.random() - 0.5) * area.Size.Z
	local top = area.CFrame * CFrame.new(x, 200, z)
	-- Shoot a ray down to find the ground
	local hit = workspace:Raycast(top.Position, Vector3.new(0, -400, 0), rayParams)
	if hit then
		local list = templates and templates:GetChildren() or {}
		local tree = #list > 0 and list[math.random(#list)]:Clone() or simpleTree()
		tree:ScaleTo(MIN_SCALE + math.random() * (MAX_SCALE - MIN_SCALE))
		local bottomOffset = tree:GetPivot().Position.Y - tree:GetBoundingBox().Position.Y + tree:GetExtentsSize().Y / 2
		tree:PivotTo(CFrame.new(hit.Position + Vector3.new(0, bottomOffset, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
		tree.Parent = forest
	end
end
