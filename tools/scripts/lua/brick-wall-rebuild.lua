-- @title Knock-down brick wall
-- @category World and effects
-- @kind Script
-- @where Put this Script inside an Anchored Part placed where the wall should stand (the part becomes the wall's floor marker).
-- @keywords brick wall, knock down wall, physics bricks, wall falls apart, destructible bricks
-- @about Builds a wall of loose physics bricks that players can smash through, and rebuilds it every so often.

-- Settings: change these numbers!
local BRICKS_WIDE = 8
local BRICKS_HIGH = 6
local BRICK_SIZE = Vector3.new(4, 2, 2)
local REBUILD_EVERY = 45 -- seconds

local base = script.Parent
base.Transparency = 1
base.CanCollide = false

local wall = Instance.new("Model")
wall.Name = "BrickWall"
wall.Parent = workspace

local function build()
	wall:ClearAllChildren()
	for row = 0, BRICKS_HIGH - 1 do
		-- Every other row is shifted half a brick, like a real wall
		local shift = (row % 2 == 1) and BRICK_SIZE.X / 2 or 0
		for column = 0, BRICKS_WIDE - 1 do
			local brick = Instance.new("Part")
			brick.Size = BRICK_SIZE
			brick.Material = Enum.Material.Brick
			brick.Color = Color3.fromRGB(150 + math.random(-15, 15), 70, 50)
			local x = (column - BRICKS_WIDE / 2 + 0.5) * BRICK_SIZE.X + shift
			local y = row * BRICK_SIZE.Y + BRICK_SIZE.Y / 2
			brick.CFrame = base.CFrame * CFrame.new(x, y - base.Size.Y / 2, 0)
			brick.Parent = wall
		end
	end
	-- Let the server do the physics so everyone sees the same mess
	for _, brick in ipairs(wall:GetChildren()) do
		brick:SetNetworkOwner(nil)
	end
end

while true do
	build()
	task.wait(REBUILD_EVERY)
end
