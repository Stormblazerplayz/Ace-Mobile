-- @title Win streak stat
-- @category Leaderboards
-- @kind Script
-- @where Put this Script in ServerScriptService. It watches leaderstats Wins (given by round scripts).
-- @keywords win streak, winning streak, streak counter, wins in a row, hot streak
-- @about Adds a Streak stat that goes up each time you win without dying in between, and resets to 0 when you are knocked out.

local Players = game:GetService("Players")

-- Settings: change these!
local SHOUT_AT = { 3, 5, 10 } -- announce streaks of these sizes

Players.PlayerAdded:Connect(function(player)
	local leaderstats = player:WaitForChild("leaderstats")
	local wins = leaderstats:WaitForChild("Wins")
	local streak = Instance.new("IntValue")
	streak.Name = "Streak"
	streak.Parent = leaderstats

	local lastWins = wins.Value
	wins.Changed:Connect(function(value)
		if value > lastWins then
			streak.Value += value - lastWins
			if table.find(SHOUT_AT, streak.Value) then
				workspace:SetAttribute("Announcement", "")
				workspace:SetAttribute("Announcement", player.DisplayName .. " is on a " .. streak.Value .. " win streak!")
			end
		end
		lastWins = value
	end)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			streak.Value = 0 -- dying ends the streak
		end)
	end)
end)
