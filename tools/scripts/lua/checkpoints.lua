-- @title Checkpoints
-- @category Obstacles
-- @kind Script
-- @where Put this Script in ServerScriptService, then make a Folder named Checkpoints in Workspace with SpawnLocations inside named 1, 2, 3 and so on (1 is the start).
-- @keywords checkpoint, save my spot, respawn at checkpoint, obby checkpoints, spawn where i left off
-- @about Touching a checkpoint makes it the place where you come back to life.

local Players = game:GetService("Players")

local checkpoints = workspace:WaitForChild("Checkpoints")
local best = {} -- the highest checkpoint each player reached

-- Get ready a checkpoint so touching it saves your spot
local function setupCheckpoint(checkpoint)
	if not checkpoint:IsA("SpawnLocation") then
		return
	end
	checkpoint.Neutral = true -- everyone can use it, any team

	checkpoint.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local number = tonumber(checkpoint.Name)
		if not player or not number then
			return
		end
		-- Only save if it's further than before (no going back!)
		if number > (best[player] or 0) then
			best[player] = number
			player.RespawnLocation = checkpoint
		end
	end)
end

for _, checkpoint in ipairs(checkpoints:GetChildren()) do
	setupCheckpoint(checkpoint)
end
checkpoints.ChildAdded:Connect(setupCheckpoint)

-- New players start at checkpoint 1
local function onPlayerAdded(player)
	local first = checkpoints:FindFirstChild("1")
	if first and first:IsA("SpawnLocation") then
		best[player] = 1
		player.RespawnLocation = first
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	best[player] = nil
end)
