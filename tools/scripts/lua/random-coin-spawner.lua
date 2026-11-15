-- @title Random coin spawner
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside a big invisible, non-colliding Anchored Part that covers the area where coins should appear.
-- @keywords coin spawner, spawn coins randomly, coins appear around the map, random pickups, coin field
-- @about Keeps the area filled with coins at random spots; collected coins are replaced by new ones.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local MAX_COINS = 20
local SPAWN_EVERY = 1.5
local COIN_VALUE = 1

local area = script.Parent
area.Transparency = 1
area.CanCollide = false
area.CanTouch = false

local folder = Instance.new("Folder")
folder.Name = "SpawnedCoins"
folder.Parent = workspace

local function spawnCoin()
	local x = (math.random() - 0.5) * area.Size.X
	local z = (math.random() - 0.5) * area.Size.Z
	local coin = Instance.new("Part")
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.3, 2, 2)
	coin.Anchored = true
	coin.CanCollide = false
	coin.Material = Enum.Material.Neon
	coin.Color = Color3.fromRGB(255, 215, 0)
	coin.CFrame = area.CFrame * CFrame.new(x, 0, z) * CFrame.Angles(0, 0, math.rad(90))
	coin.Parent = folder

	coin.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local stats = player and player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if coins and coin.Parent then
			coin.Parent = nil -- remove first so it is only collected once
			coins.Value = coins.Value + COIN_VALUE
			coin:Destroy()
		end
	end)
end

while true do
	if #folder:GetChildren() < MAX_COINS then
		spawnCoin()
	end
	task.wait(SPAWN_EVERY)
end
