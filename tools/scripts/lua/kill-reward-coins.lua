-- @title Coins for defeating players
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService (weapons must tag hits with a creator value, like the Creator tag module does).
-- @keywords kill reward, coins for kills, bounty, reward for defeating, killer gets coins
-- @about When someone is defeated, the player who hit them last gets coins as a reward.

local Players = game:GetService("Players")

-- Settings: change this number!
local REWARD = 25

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		-- Weapons put an ObjectValue named "creator" in the humanoid pointing at the attacker
		local tag = humanoid:FindFirstChild("creator")
		local killer = tag and tag.Value
		if not killer or not killer:IsA("Player") or killer.Character == character then
			return
		end
		local stats = killer:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if coins then
			coins.Value += REWARD
			killer:SetAttribute("Notice", "+" .. REWARD .. " coins for the takedown!")
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)
