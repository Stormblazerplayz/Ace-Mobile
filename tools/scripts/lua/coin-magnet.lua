-- @title Coin magnet
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService and give your coin Parts the tag Coin (works great with the Coin pickup script inside each coin).
-- @keywords coin magnet, magnet pulls coins, attract pickups, magnet power, coins fly to you
-- @about Coins close to a player fly toward them so they are easier to collect; players with the Magnet attribute pull from further away.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local NORMAL_RANGE = 8 -- studs
local MAGNET_RANGE = 30 -- studs for players whose "Magnet" attribute is true
local PULL_SPEED = 40 -- studs per second

RunService.Heartbeat:Connect(function(deltaTime)
	local coins = CollectionService:GetTagged("Coin")
	if #coins == 0 then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local range = player:GetAttribute("Magnet") and MAGNET_RANGE or NORMAL_RANGE
			for _, coin in ipairs(coins) do
				if coin:IsA("BasePart") and coin.Anchored and coin.Transparency < 1 then
					local toPlayer = root.Position - coin.Position
					local distance = toPlayer.Magnitude
					if distance < range and distance > 0.5 then
						-- Move a small step toward the player each frame
						local step = math.min(PULL_SPEED * deltaTime, distance)
						coin.CFrame = coin.CFrame + toPlayer.Unit * step
					end
				end
			end
		end
	end
end)
