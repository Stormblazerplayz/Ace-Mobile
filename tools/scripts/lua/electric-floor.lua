-- @title Electric floor
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored floor Part.
-- @keywords electric floor, shock floor, zapping floor, floor turns deadly, warning floor
-- @about The floor flashes yellow as a warning, then turns electric blue and shocks anyone standing on it.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local SAFE_TIME = 3
local WARNING_TIME = 1.5
local SHOCK_TIME = 2
local DAMAGE_PER_TICK = 15 -- damage every 0.2 seconds while shocking

local floor = script.Parent
local safeColor = floor.Color
local safeMaterial = floor.Material

-- Find humanoids standing on top of the floor (in a thin box just above it)
local function humanoidsOnTop()
	local found = {}
	local boxCFrame = floor.CFrame * CFrame.new(0, floor.Size.Y / 2 + 1.5, 0)
	local boxSize = Vector3.new(floor.Size.X, 3, floor.Size.Z)
	for _, part in ipairs(workspace:GetPartBoundsInBox(boxCFrame, boxSize)) do
		local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) then
			found[humanoid] = true
		end
	end
	return found
end

while true do
	-- Safe
	floor.Color = safeColor
	floor.Material = safeMaterial
	task.wait(SAFE_TIME)

	-- Warning: blink yellow
	for _ = 1, math.floor(WARNING_TIME / 0.25) do
		floor.Color = Color3.fromRGB(255, 220, 0)
		task.wait(0.125)
		floor.Color = safeColor
		task.wait(0.125)
	end

	-- Shock!
	floor.Color = Color3.fromRGB(0, 170, 255)
	floor.Material = Enum.Material.Neon
	local shockEnd = os.clock() + SHOCK_TIME
	while os.clock() < shockEnd do
		for humanoid in pairs(humanoidsOnTop()) do
			humanoid:TakeDamage(DAMAGE_PER_TICK)
		end
		task.wait(0.2)
	end
end
