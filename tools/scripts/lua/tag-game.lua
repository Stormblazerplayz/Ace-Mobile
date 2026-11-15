-- @title Tag, you're it!
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords tag game, you are it, freeze tag, chase game, playground tag
-- @about One random player is "It" and glows red; touching another player makes them It, and whoever is It the least time wins.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local ROUND_TIME = 120
local TAG_COOLDOWN = 2 -- seconds before you can tag back

local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local it = nil
local lastTag = 0
local timeAsIt = {}

local function setIt(player)
	if it and it.Character then
		local old = it.Character:FindFirstChild("ItGlow")
		if old then
			old:Destroy()
		end
	end
	it = player
	lastTag = os.clock()
	if player and player.Character then
		local glow = Instance.new("Highlight")
		glow.Name = "ItGlow"
		glow.FillColor = Color3.fromRGB(255, 40, 40)
		glow.Parent = player.Character
		status.Value = player.Name .. " is IT!"
	end
end

-- Watch every character's parts for touches from the It player
local function hookCharacter(player, character)
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local toucher = Players:GetPlayerFromCharacter(hit.Parent)
				if toucher and toucher == it and player ~= it and os.clock() - lastTag > TAG_COOLDOWN then
					setIt(player)
				end
			end)
		end
	end
end
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		hookCharacter(player, character)
		if player == it then
			setIt(player) -- put the glow back after respawning
		end
	end)
end)

while true do
	while #Players:GetPlayers() < 2 do
		status.Value = "Need 2 players for tag"
		task.wait(2)
	end
	timeAsIt = {}
	local everyone = Players:GetPlayers()
	setIt(everyone[math.random(1, #everyone)])
	for t = ROUND_TIME, 1, -1 do
		task.wait(1)
		if not it or not it.Parent then
			local list = Players:GetPlayers()
			setIt(list[math.random(1, #list)])
		end
		timeAsIt[it] = (timeAsIt[it] or 0) + 1
	end
	-- Winner: the player who was It for the shortest time
	local best, bestTime = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local seconds = timeAsIt[player] or 0
		if seconds < bestTime then
			best, bestTime = player, seconds
		end
	end
	setIt(nil)
	status.Value = best and (best.Name .. " wins tag!") or "Tag over"
	task.wait(8)
end
