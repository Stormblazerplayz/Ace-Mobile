-- @title Hide and seek
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService and put a Part named SeekerWait in a closed room (the seeker waits there while others hide).
-- @keywords hide and seek, seeker, hiders, find everyone, hiding game
-- @about One seeker waits while everyone hides, then hunts them; touching a hider finds them, and hiders who last until time runs out win.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local HIDE_TIME = 30
local SEEK_TIME = 120

local seekerWait = workspace:WaitForChild("SeekerWait")
local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

while true do
	while #Players:GetPlayers() < 2 do
		status.Value = "Need 2 players"
		task.wait(2)
	end
	local everyone = Players:GetPlayers()
	local seeker = everyone[math.random(1, #everyone)]
	local hiders = {}
	for _, player in ipairs(everyone) do
		if player ~= seeker then
			hiders[player] = true
			player:LoadCharacter() -- hiders start fresh at spawn
		end
	end
	seeker:LoadCharacter()
	local seekerChar = seeker.Character or seeker.CharacterAdded:Wait()
	seekerChar:WaitForChild("HumanoidRootPart")
	seekerChar:PivotTo(seekerWait.CFrame + Vector3.new(0, 4, 0))

	for t = HIDE_TIME, 1, -1 do
		status.Value = "Hide! " .. seeker.Name .. " is seeking in " .. t
		task.wait(1)
	end
	seekerChar = seeker.Character
	local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
	if seekerChar and spawnLocation then
		seekerChar:PivotTo(spawnLocation.CFrame + Vector3.new(0, 4, 0))
	end

	-- Touching a hider with the seeker's body finds them
	local connections = {}
	if seekerChar then
		for _, part in ipairs(seekerChar:GetChildren()) do
			if part:IsA("BasePart") then
				table.insert(connections, part.Touched:Connect(function(hit)
					local found = Players:GetPlayerFromCharacter(hit.Parent)
					if found and hiders[found] then
						hiders[found] = nil
						status.Value = found.Name .. " was found!"
						found:SetAttribute("Notice", "You were found!")
					end
				end))
			end
		end
	end

	for t = SEEK_TIME, 1, -1 do
		local left = 0
		for player in pairs(hiders) do
			if player.Parent then
				left += 1
			end
		end
		if left == 0 then
			break
		end
		status.Value = left .. " hiding, " .. t .. "s left"
		task.wait(1)
	end
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	local winners = {}
	for player in pairs(hiders) do
		if player.Parent then
			table.insert(winners, player.Name)
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Wins") then
				stats.Wins.Value += 1
			end
		end
	end
	status.Value = #winners > 0 and ("Hiders win: " .. table.concat(winners, ", ")) or (seeker.Name .. " found everyone!")
	task.wait(6)
end
