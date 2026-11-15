-- @title Team by group rank
-- @category Teams
-- @kind Script
-- @where Put this Script in ServerScriptService, set GROUP_ID to your Roblox group's id, and make the teams named in RANK_TEAMS.
-- @keywords group rank team, staff team, group members team, rank based team, clan team
-- @about Puts players on a team based on their rank in your Roblox group, like Staff for high ranks, Members for anyone in the group, and Visitors for everyone else.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Settings: change these!
local GROUP_ID = 0
-- From the highest rank down: if your rank is at least minRank, you join that team
local RANK_TEAMS = {
	{ minRank = 200, team = "Staff" },
	{ minRank = 1, team = "Members" },
	{ minRank = 0, team = "Visitors" },
}

Players.PlayerAdded:Connect(function(player)
	local ok, rank = pcall(function()
		return player:GetRankInGroup(GROUP_ID)
	end)
	rank = ok and rank or 0
	for _, rule in ipairs(RANK_TEAMS) do
		if rank >= rule.minRank then
			local team = Teams:FindFirstChild(rule.team)
			if team then
				player.Team = team
				player:LoadCharacter() -- spawn at that team's spawn
			end
			break
		end
	end
end)
