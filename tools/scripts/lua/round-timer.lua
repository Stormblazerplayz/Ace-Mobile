-- @title Round timer with intermission
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService; add a normal Part named RoundSpawn where rounds start (not a SpawnLocation), and use the Round timer text script to show the time.
-- @keywords round timer, timer, intermission, round system, minigame rounds, game loop, rounds and lobby
-- @about Runs an intermission countdown, sends everyone into a round, then brings them back to the lobby, forever.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these numbers!
local INTERMISSION = 15 -- seconds in the lobby between rounds
local ROUND_TIME = 60 -- seconds each round lasts
local MIN_PLAYERS = 1 -- players needed to start (use 2 for a real game)

-- The text everyone sees, shared in ReplicatedStorage
local status = ReplicatedStorage:FindFirstChild("Status")
if not status then
	status = Instance.new("StringValue")
	status.Name = "Status"
	status.Parent = ReplicatedStorage
end

-- Count down one second at a time
local function countdown(text, seconds)
	for i = seconds, 1, -1 do
		status.Value = text .. i
		task.wait(1)
	end
end

while true do
	-- Wait until there are enough players
	while #Players:GetPlayers() < MIN_PLAYERS do
		status.Value = "Waiting for players..."
		task.wait(1)
	end

	countdown("Intermission: ", INTERMISSION)

	-- Round start: send everyone to RoundSpawn (spread out a little)
	local roundSpawn = workspace:FindFirstChild("RoundSpawn")
	if roundSpawn then
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character then
				local offset = Vector3.new(math.random(-5, 5), 5, math.random(-5, 5))
				character:PivotTo(CFrame.new(roundSpawn.Position + offset))
			end
		end
	end

	countdown("Round: ", ROUND_TIME)

	-- Round over: respawn everyone back in the lobby
	status.Value = "Round over!"
	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter()
	end
	task.wait(3)
end
