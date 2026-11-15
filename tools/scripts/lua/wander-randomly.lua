-- @title NPC wanders around
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an NPC or animal Model with a Humanoid.
-- @keywords wander, random walking, idle wandering, animal ai, roaming npc
-- @about The NPC strolls to random spots near where it started, waits a bit, and picks a new spot, like a pet or farm animal.

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")

-- Settings: change these!
local WANDER_RADIUS = 25 -- how far from home it can go
local MIN_WAIT, MAX_WAIT = 2, 6

root:SetNetworkOwner(nil)
humanoid.WalkSpeed = 8
local home = root.Position

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { npc }

while humanoid.Health > 0 do
	local angle = math.random() * math.pi * 2
	local distance = math.random() * WANDER_RADIUS
	local spot = home + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
	-- Look down from above the spot to find the ground there
	local result = workspace:Raycast(spot + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), params)
	if result and result.Material ~= Enum.Material.Water then
		humanoid:MoveTo(result.Position)
		humanoid.MoveToFinished:Wait()
	end
	task.wait(math.random(MIN_WAIT * 10, MAX_WAIT * 10) / 10)
end
