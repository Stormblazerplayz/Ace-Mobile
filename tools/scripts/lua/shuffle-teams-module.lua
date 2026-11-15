-- @title Mix up the teams (module)
-- @category Teams
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it ShuffleTeams. Call require(game.ServerScriptService.ShuffleTeams)() at the start of a round.
-- @keywords shuffle teams, random teams, scramble teams, mix players, new teams each round
-- @about Puts every player on a random team so the teams are mixed up and even, then respawns everyone at their new spawn.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- teamNames (optional): only shuffle into these teams, like {"Red", "Blue"}
return function(teamNames)
	local teams = {}
	for _, team in ipairs(Teams:GetTeams()) do
		if not teamNames or table.find(teamNames, team.Name) then
			table.insert(teams, team)
		end
	end
	if #teams == 0 then
		warn("ShuffleTeams: no teams found")
		return
	end
	-- Shuffle the players like cards
	local players = Players:GetPlayers()
	for i = #players, 2, -1 do
		local j = math.random(1, i)
		players[i], players[j] = players[j], players[i]
	end
	-- Deal them out one by one: team 1, team 2, team 1, team 2...
	for i, player in ipairs(players) do
		player.Team = teams[(i - 1) % #teams + 1]
	end
	for _, player in ipairs(players) do
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
end
