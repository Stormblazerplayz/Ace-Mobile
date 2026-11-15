-- @title Last player standing
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService and put a Part named ArenaSpawn in the arena. Players who die or fall off are out.
-- @keywords last player standing, last one alive, elimination round, survival minigame, be the last
-- @about Sends everyone into the arena; when you die you are out, and the last one alive wins a Win.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local MIN_PLAYERS = 2
local LOBBY_TIME = 15
local MAX_ROUND_TIME = 180

local arenaSpawn = workspace:WaitForChild("ArenaSpawn")
local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local function giveWin(player)
	local stats = player:FindFirstChild("leaderstats")
	local wins = stats and stats:FindFirstChild("Wins")
	if wins then
		wins.Value += 1
	end
end

while true do
	while #Players:GetPlayers() < MIN_PLAYERS do
		status.Value = "Waiting for " .. MIN_PLAYERS .. " players..."
		task.wait(2)
	end
	for t = LOBBY_TIME, 1, -1 do
		status.Value = "Round starts in " .. t
		task.wait(1)
	end

	-- Everyone who has a character is in
	local alive = {}
	local connections = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			alive[player] = true
			character:PivotTo(arenaSpawn.CFrame + Vector3.new(math.random(-10, 10), 4, math.random(-10, 10)))
			table.insert(connections, humanoid.Died:Connect(function()
				alive[player] = nil
			end))
		end
	end
	table.insert(connections, Players.PlayerRemoving:Connect(function(player)
		alive[player] = nil
	end))

	local function countAlive()
		local count, last = 0, nil
		for player in pairs(alive) do
			count += 1
			last = player
		end
		return count, last
	end

	local timeLeft = MAX_ROUND_TIME
	while timeLeft > 0 and countAlive() > 1 do
		status.Value = countAlive() .. " players left (" .. timeLeft .. ")"
		task.wait(1)
		timeLeft -= 1
	end

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	local count, winner = countAlive()
	if count == 1 and winner then
		status.Value = winner.Name .. " wins!"
		giveWin(winner)
	else
		status.Value = "Nobody won this time!"
	end
	task.wait(4)
	for player in pairs(alive) do
		player:LoadCharacter() -- survivors go back to the lobby
	end
end
