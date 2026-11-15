-- @title Hills terrain generator
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService (it builds Terrain around the middle of the map when the game starts).
-- @keywords terrain generator, random hills, procedural terrain, math noise, generate land, perlin noise
-- @about Uses math.noise to build smooth random hills out of grass, rock and sand Terrain, plus water in the low spots.

-- Settings: change these numbers!
local SIZE = 256 -- studs across (keep it a multiple of 4)
local HILL_HEIGHT = 40
local SMOOTHNESS = 80 -- bigger = wider, gentler hills
local WATER_LEVEL = 8
local SEED = math.random(1, 10000) -- a new world every time (use a number for the same world)

local terrain = workspace.Terrain
local STEP = 4 -- terrain is made of 4 stud blocks

for x = -SIZE / 2, SIZE / 2 - STEP, STEP do
	for z = -SIZE / 2, SIZE / 2 - STEP, STEP do
		-- math.noise gives a smooth bumpy number between about -0.5 and 0.5
		local n = math.noise(x / SMOOTHNESS, z / SMOOTHNESS, SEED + 0.5)
		local height = math.floor((n + 0.5) * HILL_HEIGHT / STEP) * STEP + STEP

		local material = Enum.Material.Grass
		if height <= WATER_LEVEL + STEP then
			material = Enum.Material.Sand
		elseif height > HILL_HEIGHT * 0.7 then
			material = Enum.Material.Rock
		end
		-- Fill a column from the bottom up to the height
		terrain:FillBlock(CFrame.new(x, height / 2, z), Vector3.new(STEP, height, STEP), material)

		if height < WATER_LEVEL then
			local depth = WATER_LEVEL - height
			terrain:FillBlock(CFrame.new(x, height + depth / 2, z), Vector3.new(STEP, depth, STEP), Enum.Material.Water)
		end
	end
	task.wait() -- give the server a tiny break each row
end
