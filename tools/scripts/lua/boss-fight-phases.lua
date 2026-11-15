-- @title Boss with phases
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside a boss NPC Model named Boss (with Humanoid and HumanoidRootPart). Optional: put a small enemy Model named Minion in ServerStorage. Works with the Boss health bar GUI.
-- @keywords boss fight, boss phases, boss attacks, shockwave attack, raid boss
-- @about The boss gets angrier as it loses health: at 2/3 health it speeds up and calls minions, and at 1/3 it starts stomping shockwaves.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local boss = script.Parent
local humanoid = boss:WaitForChild("Humanoid")
local root = boss:WaitForChild("HumanoidRootPart")

-- Settings: change these!
local REWARD_COINS = 500
local SHOCKWAVE_RADIUS = 25
local SHOCKWAVE_DAMAGE = 20

humanoid.MaxHealth = 2000
humanoid.Health = humanoid.MaxHealth
root:SetNetworkOwner(nil)
local phase = 1

local function shockwave()
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 120, 0)
	ring.Size = Vector3.new(0.5, 2, 2)
	ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	local size = SHOCKWAVE_RADIUS * 2
	TweenService:Create(ring, TweenInfo.new(0.5), { Size = Vector3.new(0.5, size, size), Transparency = 1 }):Play()
	task.delay(0.6, function()
		ring:Destroy()
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local theirHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		-- Jumping over the wave saves you!
		if theirRoot and theirHumanoid and (theirRoot.Position - root.Position).Magnitude < SHOCKWAVE_RADIUS and theirRoot.Position.Y < root.Position.Y + 2 then
			theirHumanoid:TakeDamage(SHOCKWAVE_DAMAGE)
		end
	end
end

local function summonMinions(count)
	local minion = ServerStorage:FindFirstChild("Minion")
	if not minion then
		return
	end
	for i = 1, count do
		local copy = minion:Clone()
		copy:PivotTo(root.CFrame * CFrame.new(math.random(-10, 10), 0, math.random(-10, 10)))
		copy.Parent = workspace
	end
end

humanoid.HealthChanged:Connect(function(health)
	local fraction = health / humanoid.MaxHealth
	if phase == 1 and fraction <= 2 / 3 then
		phase = 2
		humanoid.WalkSpeed = 22
		summonMinions(3)
	elseif phase == 2 and fraction <= 1 / 3 then
		phase = 3
		humanoid.WalkSpeed = 26
		summonMinions(5)
	end
end)

humanoid.Died:Connect(function()
	-- Everyone nearby gets the reward
	for _, player in ipairs(Players:GetPlayers()) do
		local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
		if theirRoot and coins and (theirRoot.Position - root.Position).Magnitude < 150 then
			coins.Value += REWARD_COINS
			player:SetAttribute("Notice", "Boss defeated! +" .. REWARD_COINS)
		end
	end
end)

-- In phase 3 the boss stomps every 4 seconds
while humanoid.Health > 0 do
	task.wait(4)
	if phase == 3 then
		shockwave()
	end
end
