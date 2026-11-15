-- @title Red light, green light
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService and add a Part named FinishLine to Workspace.
-- @keywords red light green light, stop and go, freeze when red, dont move game, squid game light
-- @about Players may run on green light, but anyone still moving when the light turns red is knocked out; reach the finish to win.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local GRACE = 0.5 -- seconds to stop after red is called
local MOVE_LIMIT = 2 -- how fast counts as "moving"

local finish = workspace:WaitForChild("FinishLine")
local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local isRed = false
local winners = {}

finish.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player and not winners[player] then
		winners[player] = true
		player:SetAttribute("Notice", "You made it!")
		local stats = player:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Wins") then
			stats.Wins.Value += 1
		end
		task.delay(3, function()
			winners[player] = nil
			if player.Parent then
				player:LoadCharacter() -- back to the start to play again
			end
		end)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if isRed then
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 and not winners[player] then
					local flat = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
					if flat.Magnitude > MOVE_LIMIT then
						humanoid.Health = 0
						status.Value = player.Name .. " moved!"
					end
				end
			end
		end
	end
end)

while true do
	status.Value = "GREEN LIGHT"
	workspace:SetAttribute("LightColor", "Green")
	task.wait(math.random(20, 50) / 10) -- 2 to 5 seconds
	status.Value = "RED LIGHT"
	workspace:SetAttribute("LightColor", "Red")
	task.wait(GRACE)
	isRed = true
	task.wait(math.random(20, 40) / 10)
	isRed = false
end
