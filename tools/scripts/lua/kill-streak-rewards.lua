-- @title Kill streak rewards
-- @category Tools and combat
-- @kind Script
-- @where Put this Script in ServerScriptService (weapons must leave a creator tag, like the Damage helper module does).
-- @keywords kill streak, killstreak rewards, on a streak, rampage, streak bonus
-- @about Counts how many players you defeat without dying and gives rewards at 3, 5 and 10 in a row, telling the whole server.

local Players = game:GetService("Players")

-- Settings: streak number -> what happens
local REWARDS = {
	[3] = { message = "is on a 3 kill streak!", speed = 4 },
	[5] = { message = "is on a RAMPAGE (5 streak)!", speed = 8, coins = 50 },
	[10] = { message = "is UNSTOPPABLE (10 streak)!", speed = 12, coins = 200 },
}

local streaks = {}

local function tellEveryone(text)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Notice", text)
	end
end

local function reward(killer)
	local streak = streaks[killer]
	local prize = REWARDS[streak]
	killer:SetAttribute("Streak", streak)
	if not prize then
		return
	end
	tellEveryone(killer.DisplayName .. " " .. prize.message)
	local humanoid = killer.Character and killer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and prize.speed then
		humanoid.WalkSpeed += prize.speed
	end
	local stats = killer:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins and prize.coins then
		coins.Value += prize.coins
	end
end

Players.PlayerAdded:Connect(function(player)
	streaks[player] = 0
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			-- Dying ends your own streak
			streaks[player] = 0
			player:SetAttribute("Streak", 0)
			local tag = humanoid:FindFirstChild("creator")
			local killer = tag and tag.Value
			if killer and killer:IsA("Player") and killer ~= player and streaks[killer] then
				streaks[killer] += 1
				reward(killer)
			end
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	streaks[player] = nil
end)
