-- @title Playtime rewards
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService (needs a Coins stat in leaderstats).
-- @keywords playtime rewards, rewards for playing longer, gift after minutes, stay longer bonus, time played gifts
-- @about Gives bigger and bigger coin gifts after a player has been in the server for 5, 15 and 30 minutes.

local Players = game:GetService("Players")

-- Settings: minutes played -> coins
local REWARDS = {
	{ minutes = 5, coins = 50 },
	{ minutes = 15, coins = 150 },
	{ minutes = 30, coins = 500 },
}

local joinedAt = {}
local nextReward = {}

Players.PlayerAdded:Connect(function(player)
	joinedAt[player] = os.clock()
	nextReward[player] = 1
end)

Players.PlayerRemoving:Connect(function(player)
	joinedAt[player] = nil
	nextReward[player] = nil
end)

while true do
	task.wait(5)
	for player, joined in pairs(joinedAt) do
		local reward = REWARDS[nextReward[player]]
		local minutesPlayed = (os.clock() - joined) / 60
		if reward and minutesPlayed >= reward.minutes then
			local stats = player:FindFirstChild("leaderstats")
			local coins = stats and stats:FindFirstChild("Coins")
			if coins then
				coins.Value = coins.Value + reward.coins
				player:SetAttribute("Notice", reward.minutes .. " minute gift: +" .. reward.coins .. " coins!")
			end
			nextReward[player] = nextReward[player] + 1
		end
	end
end
