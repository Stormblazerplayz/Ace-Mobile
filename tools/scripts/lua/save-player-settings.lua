-- @title Save each player's settings
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService. A LocalScript changes a setting with ReplicatedStorage.SaveSetting:FireServer("MusicOn", false), and reads it with player:GetAttribute("MusicOn").
-- @keywords save settings, remember options, player preferences, settings datastore, music setting saved
-- @about Remembers each player's chosen settings (like music on or off) and loads them as player attributes when they join.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: the only settings allowed, and their starting values
local DEFAULTS = {
	MusicOn = true,
	ShadowsOn = true,
	ShowTips = true,
}

local store = DataStoreService:GetDataStore("PlayerSettings_v1")
local remote = ReplicatedStorage:FindFirstChild("SaveSetting") or Instance.new("RemoteEvent")
remote.Name = "SaveSetting"
remote.Parent = ReplicatedStorage
local changed = {}

Players.PlayerAdded:Connect(function(player)
	local ok, saved = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	saved = (ok and type(saved) == "table") and saved or {}
	for name, default in pairs(DEFAULTS) do
		local value = saved[name]
		if type(value) ~= type(default) then
			value = default
		end
		player:SetAttribute(name, value)
	end
end)

remote.OnServerEvent:Connect(function(player, name, value)
	-- Only accept settings we know, with the right type (true/false etc)
	if DEFAULTS[name] == nil or type(value) ~= type(DEFAULTS[name]) then
		return
	end
	player:SetAttribute(name, value)
	changed[player] = true
end)

local function save(player)
	if not changed[player] then
		return -- nothing new to save
	end
	local data = {}
	for name in pairs(DEFAULTS) do
		data[name] = player:GetAttribute(name)
	end
	pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)
	changed[player] = nil
end

Players.PlayerRemoving:Connect(save)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3)
end)
