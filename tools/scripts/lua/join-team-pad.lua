-- @title Step on a pad to join a team
-- @category Teams
-- @kind Script
-- @where Put this Script inside an anchored Part. Set the part's BrickColor to the exact TeamColor of the team it should join.
-- @keywords join team pad, team pad, step to switch team, team select pad, colored team pad
-- @about Stepping on the pad puts you on the team with the same color as the pad, and sends you to that team's spawn.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local pad = script.Parent
local cooldown = {}

-- Find the team whose TeamColor matches this pad's BrickColor
local function findTeam()
	for _, team in ipairs(Teams:GetTeams()) do
		if team.TeamColor == pad.BrickColor then
			return team
		end
	end
	return nil
end

pad.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or cooldown[player] then
		return
	end
	local team = findTeam()
	if not team then
		warn("No team has the color " .. pad.BrickColor.Name)
		return
	end
	if player.Team == team then
		return
	end
	cooldown[player] = true
	player.Team = team
	player:SetAttribute("Notice", "You joined " .. team.Name .. "!")
	task.wait(1)
	player:LoadCharacter() -- go to the new team's spawn
	task.wait(2)
	cooldown[player] = nil
end)
