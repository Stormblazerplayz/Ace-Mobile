-- @title Loot crate with random rewards
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside an Anchored crate Part; put reward Tools in a Folder named CrateLoot in ServerStorage (needs a Coins stat).
-- @keywords loot crate, mystery box, random reward box, open a crate, case opening, gacha crate
-- @about Pay coins to open the crate and win a random Tool or coins; rare rewards have smaller chances.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Settings: what can drop and how likely (bigger weight = more common)
local PRICE = 250
local REWARDS = {
	{ kind = "coins", amount = 100, weight = 50 },
	{ kind = "coins", amount = 500, weight = 20 },
	{ kind = "tool", name = "Sword", weight = 25 }, -- a Tool name inside ServerStorage.CrateLoot
	{ kind = "tool", name = "Rocket Launcher", weight = 5 },
}

local crate = script.Parent
local loot = ServerStorage:WaitForChild("CrateLoot")

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Open (" .. PRICE .. " coins)"
prompt.ObjectText = "Loot Crate"
prompt.Parent = crate

local function roll()
	local total = 0
	for _, reward in ipairs(REWARDS) do
		total += reward.weight
	end
	local pick = math.random() * total
	for _, reward in ipairs(REWARDS) do
		pick -= reward.weight
		if pick <= 0 then
			return reward
		end
	end
	return REWARDS[1]
end

prompt.Triggered:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins or coins.Value < PRICE then
		player:SetAttribute("Notice", "You need " .. PRICE .. " coins")
		return
	end
	coins.Value -= PRICE
	local reward = roll()
	if reward.kind == "coins" then
		coins.Value += reward.amount
		player:SetAttribute("Notice", "You won " .. reward.amount .. " coins!")
	else
		local tool = loot:FindFirstChild(reward.name)
		local backpack = player:FindFirstChildOfClass("Backpack")
		if tool and backpack then
			tool:Clone().Parent = backpack
			player:SetAttribute("Notice", "You won a " .. reward.name .. "!")
		else
			coins.Value += PRICE -- refund if the tool is missing
		end
	end
end)
