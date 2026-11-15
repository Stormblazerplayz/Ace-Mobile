-- @title Save quest progress
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService. It saves the QuestName, QuestProgress and QuestGoal player attributes (used by the quest scripts and Quest tracker).
-- @keywords save quest, quest saving, mission progress saved, continue quest, quest datastore
-- @about Remembers which quest each player is on and how far they got, so they can finish it next time they play.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("QuestProgress_v1")
local loaded = {}
local QUEST_ATTRIBUTES = { "QuestName", "QuestProgress", "QuestGoal", "QuestsDone" }

Players.PlayerAdded:Connect(function(player)
	local ok, saved = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		return
	end
	if type(saved) == "table" then
		for _, name in ipairs(QUEST_ATTRIBUTES) do
			if saved[name] ~= nil then
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
	for _, name in ipairs(QUEST_ATTRIBUTES) do
		data[name] = player:GetAttribute(name)
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
