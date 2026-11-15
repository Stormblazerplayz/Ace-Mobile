-- @title XP and levels
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService; other server scripts can give XP by firing the BindableEvent ServerStorage.AddXP with (player, amount).
-- @keywords xp, experience points, level up, levels system, xp bar, gain levels
-- @about Adds Level to the leaderboard and an XP number; when you get enough XP you level up and the next level needs more.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Settings: change these numbers!
local XP_PER_MINUTE = 10 -- free XP just for playing
local function xpNeeded(level)
	return 100 + (level - 1) * 50 -- level 1 needs 100, level 2 needs 150, ...
end

local addXP = ServerStorage:FindFirstChild("AddXP") or Instance.new("BindableEvent")
addXP.Name = "AddXP"
addXP.Parent = ServerStorage

Players.PlayerAdded:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = stats
	-- XP is an attribute so it does not crowd the leaderboard (GUIs can read it)
	player:SetAttribute("XP", 0)
	player:SetAttribute("XPNeeded", xpNeeded(1))
end)

local function giveXP(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	local level = stats and stats:FindFirstChild("Level")
	if not level or type(amount) ~= "number" then
		return
	end
	local xp = (player:GetAttribute("XP") or 0) + amount
	-- Level up as many times as the XP allows
	while xp >= xpNeeded(level.Value) do
		xp -= xpNeeded(level.Value)
		level.Value += 1
		player:SetAttribute("Notice", "Level up! You are level " .. level.Value)
	end
	player:SetAttribute("XP", xp)
	player:SetAttribute("XPNeeded", xpNeeded(level.Value))
end

addXP.Event:Connect(giveXP)

while true do
	task.wait(60)
	for _, player in ipairs(Players:GetPlayers()) do
		giveXP(player, XP_PER_MINUTE)
	end
end
