-- @title Enemies drop loot
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an enemy NPC Model with a Humanoid. Optional: put rare item Tools in a Folder named Loot in ServerStorage.
-- @keywords loot drop, enemy drops coins, monster loot, item drop chance, drop on defeat
-- @about When this enemy is defeated it drops shiny coins anyone can grab, and sometimes a rare item.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

-- Settings: change these!
local COIN_DROPS = 3
local COINS_EACH = 10
local RARE_CHANCE = 0.1 -- 10 percent

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")

local function dropCoin(position)
	local coin = Instance.new("Part")
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.4, 2, 2)
	coin.Color = Color3.fromRGB(255, 200, 40)
	coin.Material = Enum.Material.Neon
	coin.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	coin.Parent = workspace
	-- Pop it out in a random direction
	coin.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), 30, math.random(-15, 15))
	local taken = false
	coin.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local coins = player and player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
		if coins and not taken then
			taken = true
			coins.Value += COINS_EACH
			coin:Destroy()
		end
	end)
	Debris:AddItem(coin, 30)
end

humanoid.Died:Connect(function()
	local position = root.Position
	for _ = 1, COIN_DROPS do
		dropCoin(position)
	end
	local lootFolder = ServerStorage:FindFirstChild("Loot")
	if lootFolder and math.random() < RARE_CHANCE then
		local choices = lootFolder:GetChildren()
		if #choices > 0 then
			-- A Tool dropped in the world can be picked up by walking into it
			local item = choices[math.random(1, #choices)]:Clone()
			item.Parent = workspace
			if item:FindFirstChild("Handle") then
				item.Handle.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
			end
		end
	end
end)
