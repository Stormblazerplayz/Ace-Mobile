-- @title Coin rain event
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside a big flat, invisible, non-colliding Anchored Part high in the sky over the area where coins should fall.
-- @keywords coin rain, raining coins, money falls from the sky, server event, coin shower
-- @about Every few minutes it rains coins for everyone to grab, and the whole server gets a message.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local EVENT_EVERY = 300 -- seconds between coin rains
local RAIN_TIME = 20 -- how long it rains
local COINS_PER_SECOND = 8
local COIN_VALUE = 5

local sky = script.Parent
sky.Transparency = 1
sky.CanCollide = false
sky.CanTouch = false

local function dropCoin()
	local x = (math.random() - 0.5) * sky.Size.X
	local z = (math.random() - 0.5) * sky.Size.Z
	local coin = Instance.new("Part")
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.3, 1.6, 1.6)
	coin.Color = Color3.fromRGB(255, 215, 0)
	coin.Material = Enum.Material.Neon
	coin.CFrame = sky.CFrame * CFrame.new(x, 0, z)
	coin.Parent = workspace
	local taken = false
	coin.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local stats = player and player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if coins and not taken then
			taken = true
			coins.Value += COIN_VALUE
			coin:Destroy()
		end
	end)
	Debris:AddItem(coin, 15)
end

local function tellEveryone(text)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Notice", text)
	end
end

while true do
	task.wait(EVENT_EVERY)
	tellEveryone("It's raining coins! Grab them!")
	local stop = os.clock() + RAIN_TIME
	while os.clock() < stop do
		dropCoin()
		task.wait(1 / COINS_PER_SECOND)
	end
end
