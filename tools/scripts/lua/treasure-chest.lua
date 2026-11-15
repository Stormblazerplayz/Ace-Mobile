-- @title Treasure chest with cooldown
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside an Anchored chest Part or the PrimaryPart of a chest Model (needs a Coins stat).
-- @keywords treasure chest, open chest reward, chest cooldown, loot chest, free chest every few minutes
-- @about Press E to open the chest for random coins; each player has to wait before opening it again.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local MIN_COINS = 20
local MAX_COINS = 100
local COOLDOWN_MINUTES = 10

local chest = script.Parent
local nextOpen = {} -- player -> time they can open it again

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Open"
prompt.ObjectText = "Treasure Chest"
prompt.HoldDuration = 1
prompt.Parent = chest

prompt.Triggered:Connect(function(player)
	local now = os.time()
	if nextOpen[player] and now < nextOpen[player] then
		local secondsLeft = nextOpen[player] - now
		player:SetAttribute("Notice", "Chest ready in " .. math.ceil(secondsLeft / 60) .. " min")
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins then
		return
	end
	local amount = math.random(MIN_COINS, MAX_COINS)
	coins.Value = coins.Value + amount
	nextOpen[player] = now + COOLDOWN_MINUTES * 60
	player:SetAttribute("Notice", "You found " .. amount .. " coins!")
end)

Players.PlayerRemoving:Connect(function(player)
	nextOpen[player] = nil
end)
