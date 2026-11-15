-- @title Multiplier upgrade shop (server)
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService; it makes a RemoteEvent named BuyUpgrade that a GUI button can fire (needs a Coins stat).
-- @keywords upgrade shop, buy multiplier, price goes up each level, upgrade levels, gain multiplier
-- @about Players buy upgrade levels that raise their Multiplier attribute; each level costs more than the last.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these numbers!
local BASE_PRICE = 50
local PRICE_GROWTH = 1.5 -- each level costs 1.5 times more
local BONUS_PER_LEVEL = 0.25 -- each level adds 25 percent
local MAX_LEVEL = 50

local buyUpgrade = ReplicatedStorage:FindFirstChild("BuyUpgrade") or Instance.new("RemoteEvent")
buyUpgrade.Name = "BuyUpgrade"
buyUpgrade.Parent = ReplicatedStorage

local function priceFor(level)
	return math.floor(BASE_PRICE * PRICE_GROWTH ^ level)
end

local function refresh(player)
	local level = player:GetAttribute("UpgradeLevel") or 0
	player:SetAttribute("Multiplier", 1 + level * BONUS_PER_LEVEL)
	player:SetAttribute("UpgradePrice", priceFor(level)) -- the GUI shows this
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("UpgradeLevel", player:GetAttribute("UpgradeLevel") or 0)
	refresh(player)
end)

buyUpgrade.OnServerEvent:Connect(function(player)
	local level = player:GetAttribute("UpgradeLevel") or 0
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins or level >= MAX_LEVEL then
		return
	end
	local price = priceFor(level)
	if coins.Value < price then
		player:SetAttribute("Notice", "Need " .. price .. " coins")
		return
	end
	coins.Value -= price
	player:SetAttribute("UpgradeLevel", level + 1)
	refresh(player)
end)
