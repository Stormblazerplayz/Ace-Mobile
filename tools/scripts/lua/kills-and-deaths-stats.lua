-- @title Kills and Deaths on the leaderboard
-- @category Leaderboards
-- @kind Script
-- @where Put this Script in ServerScriptService. Weapons must add a "creator" tag to victims (the weapon scripts here do).
-- @keywords kills stat, deaths stat, kills on leaderboard, kd stats, knockouts counter
-- @about Adds Kills and Deaths to the player list and counts them up every time someone is knocked out.

local Players = game:GetService("Players")

local function getStat(player, name)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(name)
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	for _, name in ipairs({ "Kills", "Deaths" }) do
		if not leaderstats:FindFirstChild(name) then
			local value = Instance.new("IntValue")
			value.Name = name
			value.Parent = leaderstats
		end
	end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			local deaths = getStat(player, "Deaths")
			if deaths then
				deaths.Value += 1
			end
			-- The creator tag tells us who did the damage last
			local tag = humanoid:FindFirstChild("creator")
			local killer = tag and tag.Value
			if killer and killer:IsA("Player") and killer ~= player then
				local kills = getStat(killer, "Kills")
				if kills then
					kills.Value += 1
				end
			end
		end)
	end)
end)
