-- @title Team points from knockouts
-- @category Teams
-- @kind Script
-- @where Put this Script in ServerScriptService. Weapons must add a "creator" tag to victims (the weapon scripts here do). Show the score with the Team score display GUI.
-- @keywords team points, team kills, score for team, team score attribute, enemy defeat points
-- @about Every time someone knocks out a player on another team, their team's Score goes up by one; the first team to the goal wins.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Settings: change these!
local GOAL = 25

local matchOver = false

local function resetScores()
	for _, team in ipairs(Teams:GetTeams()) do
		team:SetAttribute("Score", 0)
	end
end

local function onDied(victim, humanoid)
	local tag = humanoid:FindFirstChild("creator")
	local killer = tag and tag.Value
	if matchOver or not (killer and killer:IsA("Player") and killer.Team and killer.Team ~= victim.Team) then
		return
	end
	local team = killer.Team
	local score = (team:GetAttribute("Score") or 0) + 1
	team:SetAttribute("Score", score)
	if score >= GOAL then
		matchOver = true
		workspace:SetAttribute("Announcement", "")
		workspace:SetAttribute("Announcement", team.Name .. " wins the match!")
		for _, player in ipairs(team:GetPlayers()) do
			local wins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Wins")
			if wins then
				wins.Value += 1
			end
		end
		task.wait(5)
		resetScores()
		matchOver = false
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			onDied(player, humanoid)
		end)
	end)
end)
resetScores()
