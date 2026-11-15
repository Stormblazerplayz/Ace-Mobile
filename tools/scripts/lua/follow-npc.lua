-- @title NPC that follows players
-- @category World and effects
-- @kind Script
-- @where Put this Script inside an NPC Model that has a Humanoid and a HumanoidRootPart (for example a Rig made with the Rig Builder in the Avatar tab).
-- @keywords npc follow, npc that chases you, zombie chase, follower npc, enemy that follows the player
-- @about The NPC walks after the nearest player, and can hurt them if you turn on TOUCH_DAMAGE.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

-- Settings: change these!
local CHASE_DISTANCE = 100 -- players closer than this get followed
local STOP_DISTANCE = 5 -- stop walking this close to the player
local USE_PATHFINDING = false -- true = walks around walls
local TOUCH_DAMAGE = 0 -- set to 10 to make it a zombie that hurts

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")
-- Unanchor the NPC so it can walk, and let the server move it smoothly
for _, part in ipairs(npc:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = false
	end
end
pcall(function() root:SetNetworkOwner(nil) end)

-- Find the closest living player
local function findNearest()
	local nearest, nearestDistance = nil, CHASE_DISTANCE
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local theirRoot = character and character:FindFirstChild("HumanoidRootPart")
		local theirHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if theirRoot and theirHumanoid and theirHumanoid.Health > 0 then
			local distance = (theirRoot.Position - root.Position).Magnitude
			if distance < nearestDistance then
				nearest, nearestDistance = theirRoot, distance
			end
		end
	end
	return nearest, nearestDistance
end

-- Walk toward a spot (around walls if pathfinding is on)
local function walkTo(position)
	if USE_PATHFINDING then
		local path = PathfindingService:CreatePath()
		local ok = pcall(function()
			path:ComputeAsync(root.Position, position)
		end)
		local waypoints = ok and path.Status == Enum.PathStatus.Success and path:GetWaypoints()
		local nextPoint = waypoints and (waypoints[2] or waypoints[1])
		if nextPoint then
			if nextPoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			humanoid:MoveTo(nextPoint.Position)
			return
		end
	end
	humanoid:MoveTo(position)
end

-- Hurt players it touches (only if TOUCH_DAMAGE is more than 0)
local lastHit = {}
humanoid.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	local theirHumanoid = player and hit.Parent:FindFirstChildOfClass("Humanoid")
	local now = os.clock()
	-- Only hurt the same player once per second
	if TOUCH_DAMAGE > 0 and theirHumanoid and now - (lastHit[player] or 0) >= 1 then
		lastHit[player] = now
		theirHumanoid:TakeDamage(TOUCH_DAMAGE)
	end
end)

-- Keep chasing while the NPC is alive
while humanoid.Health > 0 do
	local target, distance = findNearest()
	if target and distance > STOP_DISTANCE then
		walkTo(target.Position)
	end
	task.wait(0.25)
end
