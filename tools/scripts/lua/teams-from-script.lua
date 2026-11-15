-- @title Make teams with a script
-- @category Teams
-- @kind Script
-- @where Put this Script in ServerScriptService and change the TEAMS list (you do not need to make Teams by hand).
-- @keywords create teams, make teams by script, team setup, add teams, team colors list
-- @about Creates all your teams from a simple list when the game starts, with the colors and settings you choose.

local Teams = game:GetService("Teams")

-- Settings: one line per team. autoJoin = new players can be put on it automatically.
local TEAMS = {
	{ name = "Red", color = "Bright red", autoJoin = true },
	{ name = "Blue", color = "Bright blue", autoJoin = true },
	{ name = "Spectators", color = "Medium stone grey", autoJoin = false },
}

for _, info in ipairs(TEAMS) do
	local team = Teams:FindFirstChild(info.name) or Instance.new("Team")
	team.Name = info.name
	team.TeamColor = BrickColor.new(info.color)
	team.AutoAssignable = info.autoJoin
	team.Parent = Teams
	-- Tip: a SpawnLocation with the same TeamColor (and Neutral off) becomes this team's spawn
end
