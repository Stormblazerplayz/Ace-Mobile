-- @title Team deathmatch round
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService and make two Teams in the Teams service. Weapons must add a "creator" tag (the weapon scripts here do).
-- @keywords team deathmatch, tdm, team kills score, team battle round, red vs blue round
-- @about Each knockout gives your team a point; when the timer runs out the team with the most points wins and every player on it gets a Win.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local ROUND_TIME = 180

local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local teamScores = {}

local function scoreText()
	local parts = {}
	for _, team in ipairs(Teams:GetTeams()) do
		table.insert(parts, team.Name .. " " .. (teamScores[team] or 0))
	end
	return table.concat(parts, "  vs  ")
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			local tag = humanoid:FindFirstChild("creator")
			local killer = tag and tag.Value
			if killer and killer:IsA("Player") and killer.Team and killer.Team ~= player.Team then
				teamScores[killer.Team] = (teamScores[killer.Team] or 0) + 1
			end
		end)
	end)
end)

while true do
	teamScores = {}
	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter() -- everyone starts at their team spawn
	end
	for t = ROUND_TIME, 1, -1 do
		status.Value = scoreText() .. "   (" .. t .. ")"
		task.wait(1)
	end
	local best, bestScore, tie = nil, -1, false
	for _, team in ipairs(Teams:GetTeams()) do
		local score = teamScores[team] or 0
		if score > bestScore then
			best, bestScore, tie = team, score, false
		elseif score == bestScore then
			tie = true
		end
	end
	if best and not tie then
		status.Value = best.Name .. " team wins! " .. scoreText()
		for _, player in ipairs(best:GetPlayers()) do
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Wins") then
				stats.Wins.Value += 1
			end
		end
	else
		status.Value = "It's a tie! " .. scoreText()
	end
	task.wait(8)
end
