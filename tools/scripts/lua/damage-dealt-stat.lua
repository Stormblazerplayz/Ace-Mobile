-- @title Damage dealt stat
-- @category Leaderboards
-- @kind Script
-- @where Put this Script in ServerScriptService. Weapons must add a "creator" tag to what they hit (the weapon scripts here do).
-- @keywords damage dealt, total damage stat, damage leaderboard, hit points dealt, dps stat
-- @about Adds a Damage stat to the player list that adds up all the damage each player does to players and enemies.

local Players = game:GetService("Players")

local function watchHumanoid(humanoid)
	local lastHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		local lost = lastHealth - health
		lastHealth = health
		if lost <= 0 then
			return -- healing, not damage
		end
		-- Whoever tagged this humanoid most recently gets the credit
		local tag = humanoid:FindFirstChild("creator")
		local attacker = tag and tag.Value
		if attacker and attacker:IsA("Player") and attacker.Character ~= humanoid.Parent then
			local stat = attacker:FindFirstChild("leaderstats") and attacker.leaderstats:FindFirstChild("Damage")
			if stat then
				stat.Value += math.floor(lost + 0.5)
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local damage = Instance.new("IntValue")
	damage.Name = "Damage"
	damage.Parent = leaderstats
end)

-- Watch every Humanoid in the world: players and NPCs
for _, object in ipairs(workspace:GetDescendants()) do
	if object:IsA("Humanoid") then
		watchHumanoid(object)
	end
end
workspace.DescendantAdded:Connect(function(object)
	if object:IsA("Humanoid") then
		watchHumanoid(object)
	end
end)
