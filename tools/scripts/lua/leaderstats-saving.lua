-- @title Leaderstats with saving
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService, and to test saving in Studio turn on Game Settings > Security > Enable Studio Access to API Services.
-- @keywords leaderstats, saving, save coins, datastore, save data, money that saves, coins leaderboard
-- @about Adds a Coins number to the leaderboard and saves it, so players keep their coins next time they play.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: change these!
local STAT_NAME = "Coins" -- the name shown on the leaderboard
local START_AMOUNT = 0 -- coins a brand new player gets
local AUTOSAVE_EVERY = 120 -- seconds between autosaves

local store = DataStoreService:GetDataStore("PlayerCoins_v1")
local loaded = {} -- only save players whose coins loaded fine, so we never wipe them

local function onPlayerAdded(player)
	-- The folder MUST be named "leaderstats" (all lowercase)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local stat = Instance.new("IntValue")
	stat.Name = STAT_NAME
	stat.Value = START_AMOUNT
	stat.Parent = leaderstats

	-- Load saved coins (pcall stops errors from breaking the script)
	local ok, saved = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if ok and player.Parent then
		if typeof(saved) == "number" then
			stat.Value = saved
		end
		loaded[player] = true
	elseif not ok then
		warn("Could not load coins for " .. player.Name .. ": " .. tostring(saved))
	end
end

local function save(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(STAT_NAME)
	if not loaded[player] or not stat then return end
	local ok, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, stat.Value)
	end)
	if not ok then
		warn("Could not save coins for " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Save when a player leaves
Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player] = nil
end)

-- Save everyone when the server shuts down
game:BindToClose(function()
	local left = 0
	for _, player in ipairs(Players:GetPlayers()) do
		left = left + 1
		task.spawn(function()
			save(player)
			left = left - 1
		end)
	end
	while left > 0 do task.wait() end
end)

-- Autosave every few minutes, just in case
while true do
	task.wait(AUTOSAVE_EVERY)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
end
