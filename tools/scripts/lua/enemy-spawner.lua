-- @title Keep enemies in an area
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an anchored, see-through Part that covers the spawning area (CanCollide off). Put the enemy Model in ServerStorage and type its name in ENEMY_NAME.
-- @keywords enemy spawner, mob spawner, spawn area, keep enemies alive, monster spawn zone
-- @about Keeps a set number of enemies alive inside the area, spawning a new one a few seconds after one is defeated.

local ServerStorage = game:GetService("ServerStorage")

-- Settings: change these!
local ENEMY_NAME = "Enemy"
local MAX_ENEMIES = 5
local SPAWN_DELAY = 5

local area = script.Parent
local template = ServerStorage:WaitForChild(ENEMY_NAME)
local alive = 0

local holder = Instance.new("Folder")
holder.Name = area.Name .. "Enemies"
holder.Parent = workspace

local function randomSpot()
	local half = area.Size / 2
	local local_ = Vector3.new(math.random(-half.X, half.X), 0, math.random(-half.Z, half.Z))
	return area.CFrame * CFrame.new(local_) + Vector3.new(0, 3, 0)
end

local function spawnOne()
	local enemy = template:Clone()
	enemy:PivotTo(randomSpot())
	enemy.Parent = holder
	alive += 1
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.Died:Once(function()
		alive -= 1
		task.wait(3)
		enemy:Destroy() -- clean up the body
	end)
end

while true do
	if alive < MAX_ENEMIES then
		spawnOne()
		task.wait(SPAWN_DELAY)
	else
		task.wait(1)
	end
end
