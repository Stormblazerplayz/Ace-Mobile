-- @title No jumping zone
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored, non-colliding Part that covers the area where jumping is not allowed.
-- @keywords no jump zone, cant jump here, disable jumping, jumping not allowed, walk only area
-- @about Players inside the zone cannot jump until they walk out of it.

local Players = game:GetService("Players")

local zone = script.Parent
zone.CanCollide = false
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { zone }

local blocked = {} -- humanoid -> the jump numbers they had before

while true do
	task.wait(0.2)
	local inside = {}
	for _, part in ipairs(workspace:GetPartsInPart(zone, params)) do
		local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) then
			inside[humanoid] = true
		end
	end

	for humanoid in pairs(inside) do
		if not blocked[humanoid] then
			blocked[humanoid] = { humanoid.JumpHeight, humanoid.JumpPower }
			humanoid.JumpHeight = 0
			humanoid.JumpPower = 0 -- for games that use JumpPower instead
		end
	end

	for humanoid, old in pairs(blocked) do
		if not inside[humanoid] then
			if humanoid.Parent then
				humanoid.JumpHeight = old[1]
				humanoid.JumpPower = old[2]
			end
			blocked[humanoid] = nil
		end
	end
end
