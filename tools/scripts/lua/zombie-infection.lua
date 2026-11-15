-- @title Zombie infection round
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords zombie infection, infected round, zombies vs humans, outbreak game, infect players
-- @about One player starts as a green zombie; zombies turn humans into zombies by touching them, and humans who survive the timer win.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local ROUND_TIME = 120
local ZOMBIE_SPEED = 18

local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local zombies = {}
local roundOn = false

local function makeZombie(player)
	zombies[player] = true
	local character = player.Character
	if not character then
		return
	end
	local glow = Instance.new("Highlight")
	glow.Name = "ZombieGlow"
	glow.FillColor = Color3.fromRGB(60, 200, 60)
	glow.Parent = character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = ZOMBIE_SPEED
	end
	-- Touching with a zombie body infects humans
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local victim = Players:GetPlayerFromCharacter(hit.Parent)
				if roundOn and zombies[player] and victim and not zombies[victim] then
					makeZombie(victim)
					status.Value = victim.Name .. " got infected!"
				end
			end)
		end
	end
end

local function humansLeft()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if not zombies[player] then
			table.insert(list, player)
		end
	end
	return list
end

while true do
	while #Players:GetPlayers() < 2 do
		status.Value = "Need 2 players"
		task.wait(2)
	end
	-- Fresh characters for everyone (removes old zombie looks)
	zombies = {}
	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter()
	end
	for t = 10, 1, -1 do
		status.Value = "Run! Patient zero in " .. t
		task.wait(1)
	end
	local everyone = Players:GetPlayers()
	roundOn = true
	makeZombie(everyone[math.random(1, #everyone)])
	for t = ROUND_TIME, 1, -1 do
		local humans = humansLeft()
		if #humans == 0 then
			break
		end
		status.Value = #humans .. " humans left, " .. t .. "s"
		task.wait(1)
	end
	roundOn = false
	local survivors = humansLeft()
	if #survivors > 0 then
		status.Value = "Humans survive!"
		for _, player in ipairs(survivors) do
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Wins") then
				stats.Wins.Value += 1
			end
		end
	else
		status.Value = "The zombies took over!"
	end
	task.wait(6)
end
