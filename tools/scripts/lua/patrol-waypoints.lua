-- @title Guard walks a patrol route
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an NPC Model with a Humanoid. Put Parts named 1, 2, 3... in a Folder named PatrolPoints inside the NPC model (make them invisible and CanCollide off).
-- @keywords patrol, waypoints route, walk between points, guard route, npc patrol path
-- @about The NPC walks from point 1 to 2 to 3 and back to 1 again forever, stopping for a moment at each point.

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")
local pointsFolder = npc:WaitForChild("PatrolPoints")

-- Settings: change these!
local PAUSE_AT_POINT = 1.5
local WALK_SPEED = 10

humanoid.WalkSpeed = WALK_SPEED
root:SetNetworkOwner(nil)

-- Sort the points by their number names
local points = {}
for _, part in ipairs(pointsFolder:GetChildren()) do
	if tonumber(part.Name) then
		table.insert(points, part)
	end
end
table.sort(points, function(a, b)
	return tonumber(a.Name) < tonumber(b.Name)
end)

-- Move the folder out of the NPC so the points stay still when the NPC walks
pointsFolder.Parent = workspace
pointsFolder.Name = npc.Name .. "PatrolPoints"

if #points == 0 then
	warn("Add Parts named 1, 2, 3 to PatrolPoints")
	return
end

local index = 1
while humanoid.Health > 0 do
	humanoid:MoveTo(points[index].Position)
	humanoid.MoveToFinished:Wait()
	task.wait(PAUSE_AT_POINT)
	index = index % #points + 1 -- after the last point, go back to 1
end
