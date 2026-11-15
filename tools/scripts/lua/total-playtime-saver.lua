-- @title Total time played (saved)
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords total playtime, minutes played saved, time played stat, hours in game, playtime datastore
-- @about Adds a Minutes stat to the leaderboard that counts up while you play and is saved forever.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("Playtime_v1")
local seconds = {} -- exact seconds, so we do not lose the part of a minute
local loaded = {}

Players.PlayerAdded:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local minutes = Instance.new("IntValue")
	minutes.Name = "Minutes"
	minutes.Parent = leaderstats

	local ok, saved = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		return
	end
	seconds[player] = type(saved) == "number" and saved or 0
	minutes.Value = math.floor(seconds[player] / 60)
	loaded[player] = true
end)

local function save(player)
	if loaded[player] then
		pcall(function()
			store:SetAsync("Player_" .. player.UserId, seconds[player])
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player], seconds[player] = nil, nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3)
end)

-- Count up every second
while true do
	task.wait(1)
	for player in pairs(loaded) do
		seconds[player] += 1
		local stats = player:FindFirstChild("leaderstats")
		local minutes = stats and stats:FindFirstChild("Minutes")
		if minutes then
			minutes.Value = math.floor(seconds[player] / 60)
		end
	end
end
