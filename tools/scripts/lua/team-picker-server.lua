-- @title Choose your team (server part)
-- @category Teams
-- @kind Script
-- @where Put this Script in ServerScriptService. Use it with the Team picker buttons LocalScript.
-- @keywords pick team, choose team, team select server, switch team, team change remote
-- @about Lets players switch teams from a menu, but only to a team that is not already bigger than the others.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local COOLDOWN = 5
local MAX_DIFFERENCE = 1 -- a team can have at most this many more players than the smallest

local pickTeam = ReplicatedStorage:FindFirstChild("PickTeam") or Instance.new("RemoteEvent")
pickTeam.Name = "PickTeam"
pickTeam.Parent = ReplicatedStorage
local lastPick = {}

pickTeam.OnServerEvent:Connect(function(player, team)
	-- Never trust the client: check it is a real Team
	if typeof(team) ~= "Instance" or not team:IsA("Team") or team.Parent ~= Teams or player.Team == team then
		return
	end
	if os.clock() - (lastPick[player] or 0) < COOLDOWN then
		player:SetAttribute("Notice", "Wait a moment before switching again")
		return
	end
	local smallest = math.huge
	for _, other in ipairs(Teams:GetTeams()) do
		local count = #other:GetPlayers()
		if other == player.Team then
			count -= 1 -- do not count yourself on your old team
		end
		smallest = math.min(smallest, count)
	end
	if #team:GetPlayers() + 1 - smallest > MAX_DIFFERENCE then
		player:SetAttribute("Notice", team.Name .. " is full right now")
		return
	end
	lastPick[player] = os.clock()
	player.Team = team
	player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
	lastPick[player] = nil
end)
