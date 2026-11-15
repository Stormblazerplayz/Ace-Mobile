-- @title First to 10 knockouts
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService. Weapons must tag victims with a "creator" ObjectValue (the weapon scripts here do).
-- @keywords free for all, first to ten kills, kill race, deathmatch round, ffa round
-- @about A free-for-all round where the first player to knock out 10 others wins, then everyone's round score resets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local KILLS_TO_WIN = 10

local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local roundKills = {}
local roundActive = true

local function leader()
	local best, bestKills = nil, 0
	for player, kills in pairs(roundKills) do
		if kills > bestKills and player.Parent then
			best, bestKills = player, kills
		end
	end
	return best, bestKills
end

local function onDied(humanoid)
	if not roundActive then
		return
	end
	local tag = humanoid:FindFirstChild("creator")
	local killer = tag and tag.Value
	if not (killer and killer:IsA("Player")) then
		return
	end
	roundKills[killer] = (roundKills[killer] or 0) + 1
	killer:SetAttribute("RoundKills", roundKills[killer])
	local best, bestKills = leader()
	status.Value = best.Name .. " leads with " .. bestKills .. " / " .. KILLS_TO_WIN
	if roundKills[killer] >= KILLS_TO_WIN then
		roundActive = false
		status.Value = killer.Name .. " wins the round!"
		local stats = killer:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Wins") then
			stats.Wins.Value += 1
		end
		task.wait(6)
		roundKills = {}
		for _, player in ipairs(Players:GetPlayers()) do
			player:SetAttribute("RoundKills", 0)
			player:LoadCharacter()
		end
		status.Value = "New round! First to " .. KILLS_TO_WIN
		roundActive = true
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			onDied(humanoid)
		end)
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	roundKills[player] = nil
end)
status.Value = "First to " .. KILLS_TO_WIN .. " knockouts wins!"
