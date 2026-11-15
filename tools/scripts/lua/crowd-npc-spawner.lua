-- @title Townspeople walking around
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script in ServerScriptService. Put a simple NPC Model named Walker in ServerStorage, and Parts in a Folder named StreetPoints in Workspace (corners of your sidewalks).
-- @keywords crowd npcs, townspeople, city walkers, background npcs, busy town
-- @about Spawns friendly NPCs that walk from one street point to another and then disappear, making your town feel busy.

local ServerStorage = game:GetService("ServerStorage")

-- Settings: change these!
local MAX_WALKERS = 8
local SPAWN_EVERY = 3

local template = ServerStorage:WaitForChild("Walker")
local points = workspace:WaitForChild("StreetPoints"):GetChildren()
local holder = Instance.new("Folder")
holder.Name = "Townspeople"
holder.Parent = workspace

local COLORS = {
	Color3.fromRGB(200, 60, 60), Color3.fromRGB(60, 120, 220), Color3.fromRGB(70, 180, 90),
	Color3.fromRGB(240, 200, 60), Color3.fromRGB(150, 80, 200),
}

local function walkOne()
	if #points < 2 then
		return
	end
	local from = points[math.random(1, #points)]
	local to
	repeat
		to = points[math.random(1, #points)]
	until to ~= from
	local walker = template:Clone()
	walker:PivotTo(from.CFrame + Vector3.new(0, 3, 0))
	-- A random shirt color so they do not all look the same
	local bodyColors = walker:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		bodyColors.TorsoColor3 = COLORS[math.random(1, #COLORS)]
	end
	walker.Parent = holder
	local humanoid = walker:FindFirstChildOfClass("Humanoid")
	humanoid.WalkSpeed = math.random(6, 10)
	local root = walker:FindFirstChild("HumanoidRootPart")
	if root then
		root:SetNetworkOwner(nil)
	end
	-- MoveTo gives up after 8 seconds, so keep asking until they arrive
	for _ = 1, 10 do
		humanoid:MoveTo(to.Position)
		if humanoid.MoveToFinished:Wait() then
			break
		end
	end
	walker:Destroy()
end

while true do
	if #holder:GetChildren() < MAX_WALKERS then
		task.spawn(walkOne)
	end
	task.wait(SPAWN_EVERY)
end
