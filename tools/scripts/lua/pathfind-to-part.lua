-- @title NPC walks to a goal around walls
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an NPC Model with a Humanoid, and put a Part named NPCGoal in Workspace (where the NPC should walk to).
-- @keywords pathfinding, walk around walls, npc go to place, find a path, smart walking npc
-- @about The NPC works out a path around walls and obstacles to reach the goal part, jumping where it needs to.

local PathfindingService = game:GetService("PathfindingService")

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")
local goal = workspace:WaitForChild("NPCGoal")

-- Let the server control the NPC's movement smoothly
root:SetNetworkOwner(nil)

local path = PathfindingService:CreatePath({
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
})

local function walkTo(target)
	local ok = pcall(function()
		path:ComputeAsync(root.Position, target)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		humanoid:MoveTo(target) -- no path found, just try walking straight
		return false
	end
	for _, waypoint in ipairs(path:GetWaypoints()) do
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end
		humanoid:MoveTo(waypoint.Position)
		-- MoveToFinished gives false if it took longer than 8 seconds (stuck)
		if not humanoid.MoveToFinished:Wait() then
			return false
		end
	end
	return true
end

-- Keep walking to the goal; if the goal moves, the NPC follows it
while humanoid.Health > 0 do
	if (root.Position - goal.Position).Magnitude > 4 then
		walkTo(goal.Position)
	end
	task.wait(1)
end
