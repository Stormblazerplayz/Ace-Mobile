-- @title Coins over time
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService, together with the Leaderstats with saving script.
-- @keywords free coins every minute, money over time, passive income, coins for playing, payday
-- @about Gives every player some coins every so often just for being in the game.

local Players = game:GetService("Players")

-- Settings: change these!
local AMOUNT = 10 -- coins given each time
local EVERY = 60 -- seconds between payouts
local STAT_NAME = "Coins" -- must match your leaderstats name

while true do
	task.wait(EVERY)

	-- Pay everyone in the server
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:FindFirstChild(STAT_NAME)
		if coins then
			coins.Value = coins.Value + AMOUNT
		end
	end
end
