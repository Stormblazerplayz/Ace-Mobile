-- @title Map voting (server part)
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService. Put map Models in a Folder named Maps in ServerStorage, each with a Part named MapSpawn. Use the Map voting buttons script for the screen.
-- @keywords map voting, vote for map, choose next map, voting system, map vote server
-- @about Shows 3 random maps, lets players vote for 15 seconds, then loads the map with the most votes.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local VOTE_TIME = 15
local ROUND_TIME = 90
local CHOICES = 3

local maps = ServerStorage:WaitForChild("Maps")
local voteEvent = ReplicatedStorage:FindFirstChild("VoteMap") or Instance.new("RemoteEvent")
voteEvent.Name = "VoteMap"
voteEvent.Parent = ReplicatedStorage

local votes = {} -- votes[player] = map name
local options = {}

voteEvent.OnServerEvent:Connect(function(player, mapName)
	if ReplicatedStorage:GetAttribute("VotingOpen") and table.find(options, mapName) then
		votes[player] = mapName
	end
end)
Players.PlayerRemoving:Connect(function(player)
	votes[player] = nil
end)

while true do
	-- Pick some random maps to vote on
	local pool = maps:GetChildren()
	options = {}
	while #options < math.min(CHOICES, #maps:GetChildren()) do
		local pick = table.remove(pool, math.random(1, #pool))
		table.insert(options, pick.Name)
	end
	votes = {}
	-- Clients read these attributes to build their buttons
	ReplicatedStorage:SetAttribute("VoteOptions", table.concat(options, ","))
	ReplicatedStorage:SetAttribute("VotingOpen", true)
	for t = VOTE_TIME, 1, -1 do
		ReplicatedStorage:SetAttribute("VoteTime", t)
		task.wait(1)
	end
	ReplicatedStorage:SetAttribute("VotingOpen", false)

	-- Count the votes (ties go to the first one listed)
	local counts = {}
	for _, name in pairs(votes) do
		counts[name] = (counts[name] or 0) + 1
	end
	local winner = options[1]
	for _, name in ipairs(options) do
		if (counts[name] or 0) > (counts[winner] or 0) then
			winner = name
		end
	end

	if winner then
		local map = maps[winner]:Clone()
		map.Name = "CurrentMap"
		map.Parent = workspace
		local spawnPart = map:FindFirstChild("MapSpawn", true)
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and spawnPart then
				player.Character:PivotTo(spawnPart.CFrame + Vector3.new(math.random(-5, 5), 4, math.random(-5, 5)))
			end
		end
		task.wait(ROUND_TIME)
		map:Destroy()
		for _, player in ipairs(Players:GetPlayers()) do
			player:LoadCharacter()
		end
	else
		task.wait(5) -- no maps yet
	end
end
