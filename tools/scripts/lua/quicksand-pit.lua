-- @title Quicksand pit
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored Part that covers the quicksand area (turn CanCollide off so players sink into it).
-- @keywords quicksand, mud pit, slow zone, sticky mud, swamp slows you down, sinking sand
-- @about Players inside the quicksand move slowly, can barely jump and lose health until they get out.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local SLOW_SPEED = 4 -- walk speed while inside
local SLOW_JUMP = 2 -- jump height while inside
local DAMAGE_PER_SECOND = 5 -- set to 0 for no damage

local zone = script.Parent
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { zone }

local stuck = {} -- humanoid -> {speed, jump} we must give back later

while true do
	task.wait(0.25)
	-- Find every humanoid with a body part inside the zone
	local inside = {}
	for _, part in ipairs(workspace:GetPartsInPart(zone, params)) do
		local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) then
			inside[humanoid] = true
		end
	end

	-- Slow down everyone inside
	for humanoid in pairs(inside) do
		if not stuck[humanoid] then
			stuck[humanoid] = { humanoid.WalkSpeed, humanoid.JumpHeight }
		end
		humanoid.WalkSpeed = SLOW_SPEED
		humanoid.JumpHeight = SLOW_JUMP
		humanoid:TakeDamage(DAMAGE_PER_SECOND * 0.25)
	end

	-- Give speed back to anyone who escaped
	for humanoid, saved in pairs(stuck) do
		if not inside[humanoid] then
			if humanoid.Parent then
				humanoid.WalkSpeed = saved[1]
				humanoid.JumpHeight = saved[2]
			end
			stuck[humanoid] = nil
		end
	end
end
