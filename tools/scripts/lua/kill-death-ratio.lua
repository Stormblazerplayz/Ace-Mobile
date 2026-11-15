-- @title K/D ratio stat
-- @category Leaderboards
-- @kind Script
-- @where Put this Script in ServerScriptService together with the Kills and Deaths on the leaderboard script.
-- @keywords kd ratio, kill death ratio, kdr, ratio stat, combat skill stat
-- @about Adds a K/D number to the player list (kills divided by deaths) that updates every time either number changes.

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local leaderstats = player:WaitForChild("leaderstats")
	local kills = leaderstats:WaitForChild("Kills")
	local deaths = leaderstats:WaitForChild("Deaths")

	-- A StringValue lets us show "1.50" with 2 decimals
	local ratio = Instance.new("StringValue")
	ratio.Name = "K/D"
	ratio.Parent = leaderstats

	local function update()
		-- Dividing by 0 is not allowed, so with 0 deaths the ratio is just the kills
		local value = kills.Value / math.max(deaths.Value, 1)
		ratio.Value = string.format("%.2f", value)
	end
	kills.Changed:Connect(update)
	deaths.Changed:Connect(update)
	update()
end)
