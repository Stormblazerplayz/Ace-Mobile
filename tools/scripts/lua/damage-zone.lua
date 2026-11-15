-- @title Damage zone
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside a Part that covers the hurting area (turn off CanCollide and make it see-through if you like).
-- @keywords damage zone, poison area, hurt zone, acid pool, toxic gas, lose health slowly
-- @about Players standing inside the zone keep losing health a little at a time.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local DAMAGE = 10 -- health lost each tick
local TICK_TIME = 1 -- seconds between ticks

local zone = script.Parent

-- Only look at things that are not the zone itself
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { zone }

while true do
	task.wait(TICK_TIME)

	-- Find every player character inside the zone (each one only once)
	local hurt = {}
	for _, hit in ipairs(workspace:GetPartsInPart(zone, params)) do
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player and not hurt[player] then
			hurt[player] = true
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid:TakeDamage(DAMAGE)
			end
		end
	end
end
