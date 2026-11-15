-- @title Sell pad (simulator)
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside an Anchored Part (needs Strength and Coins stats, like from the Click to get stronger and Leaderstats with saving scripts).
-- @keywords sell pad, sell strength, sell area, trade points for coins, simulator sell
-- @about Step on the pad to sell all your Strength and turn it into Coins.

local Players = game:GetService("Players")

-- Settings: change these!
local SELL_STAT = "Strength" -- what you sell
local MONEY_STAT = "Coins" -- what you get
local PRICE_EACH = 1 -- coins for each point sold

local pad = script.Parent
local recent = {}

pad.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or recent[player] then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	local sell = stats and stats:FindFirstChild(SELL_STAT)
	local money = stats and stats:FindFirstChild(MONEY_STAT)
	if not sell or not money or sell.Value <= 0 then
		return
	end
	recent[player] = true
	money.Value = money.Value + sell.Value * PRICE_EACH
	sell.Value = 0

	-- Flash green so they know it worked
	local oldColor = pad.Color
	pad.Color = Color3.fromRGB(80, 255, 80)
	task.wait(0.5)
	pad.Color = oldColor
	recent[player] = nil
end)
