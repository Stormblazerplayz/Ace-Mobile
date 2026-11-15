-- @title Enemy waves
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService. Put an enemy Model with a Humanoid (and its own chase script) in ServerStorage named Enemy, and Parts in a Folder named EnemySpawns in Workspace.
-- @keywords wave survival, enemy waves, zombie waves, horde mode, next wave
-- @about Sends bigger and bigger waves of enemies; when every enemy in a wave is defeated, the next wave starts and players get coins.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local ENEMIES_FIRST_WAVE = 3
local EXTRA_PER_WAVE = 2
local COINS_PER_WAVE = 25

local enemyTemplate = ServerStorage:WaitForChild("Enemy")
local spawns = workspace:WaitForChild("EnemySpawns"):GetChildren()
local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local function anyoneAlive()
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			return true
		end
	end
	return false
end

local wave = 0
while true do
	if not anyoneAlive() then
		wave = 0
		status.Value = "Waiting for players..."
		task.wait(3)
		continue
	end
	wave += 1
	for t = 5, 1, -1 do
		status.Value = "Wave " .. wave .. " in " .. t
		task.wait(1)
	end
	local count = ENEMIES_FIRST_WAVE + (wave - 1) * EXTRA_PER_WAVE
	local alive = 0
	for i = 1, count do
		local enemy = enemyTemplate:Clone()
		local spot = spawns[math.random(1, #spawns)]
		enemy:PivotTo(spot.CFrame + Vector3.new(math.random(-4, 4), 3, math.random(-4, 4)))
		enemy.Parent = workspace
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		if humanoid then
			alive += 1
			humanoid.MaxHealth += wave * 10 -- tougher every wave
			humanoid.Health = humanoid.MaxHealth
			humanoid.Died:Connect(function()
				alive -= 1
				task.delay(3, function()
					enemy:Destroy()
				end)
			end)
		end
		task.wait(0.4)
	end
	while alive > 0 and anyoneAlive() do
		status.Value = "Wave " .. wave .. ": " .. alive .. " enemies left"
		task.wait(1)
	end
	if alive == 0 then
		for _, player in ipairs(Players:GetPlayers()) do
			local stats = player:FindFirstChild("leaderstats")
			if stats and stats:FindFirstChild("Coins") then
				stats.Coins.Value += COINS_PER_WAVE * wave
			end
		end
		status.Value = "Wave " .. wave .. " cleared!"
		task.wait(3)
	else
		status.Value = "Everyone fell on wave " .. wave
		for _, object in ipairs(workspace:GetChildren()) do
			if object.Name == enemyTemplate.Name then
				object:Destroy()
			end
		end
		wave = 0
		task.wait(5)
	end
end
