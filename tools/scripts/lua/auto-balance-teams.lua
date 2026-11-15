-- @title Keep teams even
-- @category Teams
-- @kind Script
-- @where Put this Script in ServerScriptService. Make your Teams in the Teams service and turn AutoAssignable off on each one (this script does the assigning).
-- @keywords auto balance teams, even teams, fair teams, team balancing, uneven teams fix
-- @about Puts each new player on the smallest team, and when someone leaves it moves a player over if one team gets 2 or more bigger.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local function teamsBySize()
	local list = Teams:GetTeams()
	table.sort(list, function(a, b)
		return #a:GetPlayers() < #b:GetPlayers()
	end)
	return list
end

Players.PlayerAdded:Connect(function(player)
	local smallest = teamsBySize()[1]
	if smallest then
		player.Team = smallest
	end
end)

local function rebalance()
	local list = teamsBySize()
	local smallest, biggest = list[1], list[#list]
	if not smallest or smallest == biggest then
		return
	end
	if #biggest:GetPlayers() - #smallest:GetPlayers() >= 2 then
		-- Move the player who joined the big team most recently (just pick one at random)
		local members = biggest:GetPlayers()
		local mover = members[math.random(1, #members)]
		mover.Team = smallest
		mover:SetAttribute("Notice", "Moved to " .. smallest.Name .. " to keep teams fair")
		mover:LoadCharacter() -- respawn at the new team's spawn
	end
end

Players.PlayerRemoving:Connect(function()
	task.wait(1) -- let them finish leaving first
	rebalance()
end)
