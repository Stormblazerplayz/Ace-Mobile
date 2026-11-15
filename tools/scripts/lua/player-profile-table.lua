-- @title Save many stats in one table
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService (and do not also use the Leaderstats with saving script). Turn on Game Settings > Security > Enable Studio Access to API Services to test.
-- @keywords player profile, save table, save many stats, data template, one save for everything
-- @about Saves Coins, Gems, Level and Wins together in one table per player, and fills in new stats for old players automatically.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("PlayerProfile_v1")

-- Settings: every stat a new player starts with (add more any time!)
local TEMPLATE = {
	Coins = 0,
	Gems = 0,
	Level = 1,
	Wins = 0,
}

local loaded = {}

local function onPlayerAdded(player)
	local ok, data = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		player:Kick("Could not load your data. Please rejoin!") -- safer than playing with empty data
		return
	end
	data = type(data) == "table" and data or {}
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for name, startValue in pairs(TEMPLATE) do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Value = data[name] or startValue -- old players get new stats too
		value.Parent = leaderstats
	end
	leaderstats.Parent = player
	loaded[player] = true
end

local function save(player)
	if not loaded[player] then
		return
	end
	local data = {}
	for name in pairs(TEMPLATE) do
		local value = player.leaderstats:FindFirstChild(name)
		data[name] = value and value.Value or TEMPLATE[name]
	end
	local ok, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)
	if not ok then
		warn("Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player] = nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3) -- give the saves time to finish
end)
while true do
	task.wait(120)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
end
