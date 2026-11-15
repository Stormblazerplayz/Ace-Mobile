-- @title Buy coins with Robux (developer products)
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService and put your developer product ids below (only ONE script in your game may set ProcessReceipt).
-- @keywords developer product, buy coins with robux, processreceipt, dev product, robux purchase, coin packs
-- @about Safely gives coins when someone buys a developer product, and never gives them twice for the same purchase.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: product id -> coins it gives
local PRODUCTS = {
	[0] = 100, -- change 0 to your product id
	[1] = 1000,
}

local purchaseHistory = DataStoreService:GetDataStore("PurchaseHistory_v1")

local function giveCoins(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins then
		error("No Coins stat yet")
	end
	coins.Value = coins.Value + amount
end

-- Roblox calls this for every purchase (and again later if we say "not processed yet")
MarketplaceService.ProcessReceipt = function(receipt)
	local key = receipt.PlayerId .. "_" .. receipt.PurchaseId
	local ok, recorded = pcall(function()
		return purchaseHistory:UpdateAsync(key, function(alreadyGiven)
			if alreadyGiven then
				return true -- we already gave it, do nothing
			end
			local player = Players:GetPlayerByUserId(receipt.PlayerId)
			local amount = PRODUCTS[receipt.ProductId]
			if not player or not amount then
				return nil -- try again later
			end
			giveCoins(player, amount)
			return true -- remember that we gave it
		end)
	end)
	if not ok or recorded == nil then
		-- Something went wrong: Roblox will ask again later, no Robux are lost
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
