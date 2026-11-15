-- @title Save any player attributes
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService and list the attribute names you want saved in SAVE_THESE.
-- @keywords save attributes, attribute saving, generic save script, save player values, remember attributes
-- @about Saves whichever player attributes you list (numbers, text or true/false) and puts them back when the player rejoins.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: names of player attributes to save
local SAVE_THESE = { "XP", "XPNeeded", "UpgradeLevel", "Streak", "EquippedTrail" }

local store = DataStoreService:GetDataStore("PlayerAttributes_v1")
local loaded = {}

-- Only simple values can go in a DataStore
local function canSave(value)
	local kind = type(value)
	return kind == "number" or kind == "string" or kind == "boolean"
end

Players.PlayerAdded:Connect(function(player)
	local ok, saved = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		warn("Could not load attributes for " .. player.Name)
		return
	end
	if type(saved) == "table" then
		for _, name in ipairs(SAVE_THESE) do
			if canSave(saved[name]) then
				player:SetAttribute(name, saved[name])
			end
		end
	end
	loaded[player] = true
end)

local function save(player)
	if not loaded[player] then
		return
	end
	local data = {}
	for _, name in ipairs(SAVE_THESE) do
		local value = player:GetAttribute(name)
		if canSave(value) then
			data[name] = value
		end
	end
	pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player] = nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3)
end)
