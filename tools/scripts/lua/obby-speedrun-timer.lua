-- @title Obby speedrun timer
-- @category Obstacles
-- @kind Script
-- @where Put this Script in ServerScriptService, then add two Anchored Parts to Workspace named TimerStart and TimerFinish.
-- @keywords speedrun timer, obby timer, how fast did i finish, best time, stopwatch obby, time trial
-- @about Starts a stopwatch when you touch the start, stops it at the finish and shows your best time on the leaderboard.

local Players = game:GetService("Players")

local startPart = workspace:WaitForChild("TimerStart")
local finishPart = workspace:WaitForChild("TimerFinish")
local startedAt = {} -- player -> the time they touched the start

-- Make a "Best Time" stat on the leaderboard
Players.PlayerAdded:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local best = Instance.new("NumberValue")
	best.Name = "Best Time"
	best.Value = 0 -- 0 means "no time yet"
	best.Parent = leaderstats
end)

startPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		startedAt[player] = os.clock() -- touching the start again restarts the clock
	end
end)

finishPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or not startedAt[player] then
		return
	end
	local seconds = os.clock() - startedAt[player]
	startedAt[player] = nil
	seconds = math.floor(seconds * 100) / 100 -- keep 2 decimals

	local stats = player:FindFirstChild("leaderstats")
	local best = stats and stats:FindFirstChild("Best Time")
	if best and (best.Value == 0 or seconds < best.Value) then
		best.Value = seconds
	end
	player:SetAttribute("LastRunTime", seconds) -- a GUI can show this
end)

Players.PlayerRemoving:Connect(function(player)
	startedAt[player] = nil
end)
