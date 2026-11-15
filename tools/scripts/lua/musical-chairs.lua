-- @title Musical chairs
-- @category Game rounds
-- @kind Script
-- @where Put this Script inside a Folder in Workspace that holds your Seats (and optionally a Sound named Music). Players walk around the seats while the music plays.
-- @keywords musical chairs, grab a seat, music stops sit down, chair game, party game seats
-- @about While the music plays the seats are locked; when it stops everyone rushes to sit, and anyone without a seat is out until one player is left.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = script.Parent
local music = folder:FindFirstChild("Music")
local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local allSeats = {}
for _, seat in ipairs(folder:GetDescendants()) do
	if seat:IsA("Seat") then
		table.insert(allSeats, seat)
	end
end

local function setSeats(count)
	for i, seat in ipairs(allSeats) do
		seat.Transparency = i <= count and 0 or 1
		seat.CanCollide = i <= count
		seat.Disabled = true -- nobody can sit until the music stops
	end
end

while true do
	while #Players:GetPlayers() < 2 do
		status.Value = "Musical chairs needs 2 players"
		task.wait(2)
	end
	local playing = {}
	for _, player in ipairs(Players:GetPlayers()) do
		playing[player] = true
	end
	local function count()
		local n = 0
		for player in pairs(playing) do
			if player.Parent then
				n += 1
			else
				playing[player] = nil
			end
		end
		return n
	end

	while count() > 1 do
		local seats = math.min(count() - 1, #allSeats)
		setSeats(seats)
		status.Value = "Walk around the chairs!"
		if music then
			music:Play()
		end
		task.wait(math.random(8, 16))
		if music then
			music:Stop()
		end
		status.Value = "SIT DOWN!"
		for i = 1, seats do
			allSeats[i].Disabled = false
		end
		task.wait(4)
		-- Anyone playing who is not sitting is out
		for player in pairs(playing) do
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not (humanoid and humanoid.SeatPart) then
				playing[player] = nil
				player:SetAttribute("Notice", "No chair! You are out.")
				if humanoid then
					humanoid.Health = 0
				end
			end
		end
		-- Stand everyone back up
		for _, seat in ipairs(allSeats) do
			if seat.Occupant then
				seat.Occupant.Sit = false
			end
		end
		task.wait(2)
	end
	for player in pairs(playing) do
		status.Value = player.Name .. " wins musical chairs!"
		local stats = player:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Wins") then
			stats.Wins.Value += 1
		end
	end
	task.wait(6)
end
