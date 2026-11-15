-- @title Shop (server part)
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService, add a RemoteEvent named BuyItem to ReplicatedStorage, and put your Tools in a Folder named ShopItems in ServerStorage.
-- @keywords shop script, buy items with coins, sell tools, store system, spend coins
-- @about Checks a player has enough coins, takes them, and gives the Tool they bought (use it with the Shop button script).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Settings: item names and prices (each name must match a Tool in ShopItems)
local PRICES = {
	["Sword"] = 50,
	["Speed Coil"] = 100,
}
local STAT_NAME = "Coins"
local COOLDOWN = 1 -- seconds between buys (stops button spamming)

local buyItem = ReplicatedStorage:WaitForChild("BuyItem")
local shopItems = ServerStorage:WaitForChild("ShopItems")
local lastBuy = {}

-- Does the player already own this tool?
local function ownsTool(player, name)
	local gear = player:FindFirstChild("StarterGear")
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	return (gear and gear:FindFirstChild(name))
		or (backpack and backpack:FindFirstChild(name))
		or (character and character:FindFirstChild(name))
end

buyItem.OnServerEvent:Connect(function(player, itemName)
	-- Never trust the client: the server checks everything!
	if typeof(itemName) ~= "string" then
		return
	end
	local now = os.clock()
	if lastBuy[player] and now - lastBuy[player] < COOLDOWN then
		return
	end
	lastBuy[player] = now

	local price = PRICES[itemName]
	local tool = shopItems:FindFirstChild(itemName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild(STAT_NAME)
	if not price or not tool or not coins then
		buyItem:FireClient(player, itemName, false, "Not for sale")
	elseif ownsTool(player, itemName) then
		buyItem:FireClient(player, itemName, false, "You have it!")
	elseif coins.Value < price then
		buyItem:FireClient(player, itemName, false, "Need " .. price .. " coins")
	else
		-- Take the coins and give the tool (StarterGear keeps it after you respawn)
		coins.Value = coins.Value - price
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			tool:Clone().Parent = backpack
		end
		local gear = player:FindFirstChild("StarterGear")
		if gear then
			tool:Clone().Parent = gear
		end
		buyItem:FireClient(player, itemName, true, "Bought!")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastBuy[player] = nil
end)
