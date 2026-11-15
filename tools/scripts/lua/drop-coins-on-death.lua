-- @title Drop coins when you die
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService (needs a Coins stat in leaderstats).
-- @keywords drop coins on death, lose coins when you die, loot from players, steal coins, death drop
-- @about When a player dies they drop some of their coins on the ground for anyone to grab.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local DROP_PERCENT = 0.2 -- drop 20 percent of your coins
local PILES = 5 -- how many coin piles to split it into
local PILE_LIFETIME = 30

local function dropCoins(position, total)
	local each = math.floor(total / PILES)
	if each <= 0 then
		return
	end
	for _ = 1, PILES do
		local pile = Instance.new("Part")
		pile.Shape = Enum.PartType.Cylinder
		pile.Size = Vector3.new(0.4, 2, 2)
		pile.Color = Color3.fromRGB(255, 210, 50)
		pile.Material = Enum.Material.Neon
		pile.CFrame = CFrame.new(position + Vector3.new(math.random(-4, 4), 2, math.random(-4, 4)))
		pile.Parent = workspace
		pile.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), 30, math.random(-15, 15)) -- burst out!
		local taken = false
		pile.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			local stats = player and player:FindFirstChild("leaderstats")
			local coins = stats and stats:FindFirstChild("Coins")
			if coins and not taken then
				taken = true
				coins.Value = coins.Value + each
				pile:Destroy()
			end
		end)
		Debris:AddItem(pile, PILE_LIFETIME)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local root = character:WaitForChild("HumanoidRootPart")
		humanoid.Died:Connect(function()
			local stats = player:FindFirstChild("leaderstats")
			local coins = stats and stats:FindFirstChild("Coins")
			if not coins then
				return
			end
			local amount = math.floor(coins.Value * DROP_PERCENT)
			coins.Value = coins.Value - amount
			dropCoins(root.Position, amount)
		end)
	end)
end)
