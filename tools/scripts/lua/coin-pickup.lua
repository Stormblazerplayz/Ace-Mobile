-- @title Coin pickup
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside your coin Part, and add the Leaderstats with saving script to ServerScriptService so players have Coins.
-- @keywords coin pickup, coin, collect coins, collectible coin, touch coin get money, spinning coin
-- @about Touching the coin gives the player coins, then the coin comes back after a few seconds.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local COINS = 1 -- coins you get each time
local RESPAWN_TIME = 5 -- seconds before the coin comes back
local SPIN_SPEED = 90 -- degrees per second (0 = no spinning)
local STAT_NAME = "Coins" -- must match your leaderstats name

local coin = script.Parent
coin.Anchored = true
coin.CanCollide = false
local startTransparency = coin.Transparency
local collected = false

coin.Touched:Connect(function(hit)
	if collected then
		return
	end
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	local leaderstats = player and player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild(STAT_NAME)
	if not coins then
		return
	end

	-- Give the coins and hide the coin
	collected = true
	coins.Value = coins.Value + COINS
	coin.Transparency = 1

	-- Bring it back later
	task.wait(RESPAWN_TIME)
	coin.Transparency = startTransparency
	collected = false
end)

-- Spin around and around (straight up and down, no matter how the coin is turned)
RunService.Heartbeat:Connect(function(dt)
	if SPIN_SPEED ~= 0 then
		local turn = CFrame.Angles(0, math.rad(SPIN_SPEED) * dt, 0)
		coin.CFrame = CFrame.new(coin.Position) * turn * (coin.CFrame - coin.Position)
	end
end)
