-- @title Double coins game pass
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService and put your game pass id below (needs a Coins stat in leaderstats).
-- @keywords double coins, 2x coins gamepass, coin multiplier pass, earn double money, 2x money
-- @about Players who own the game pass get double every time their coins go up, from any script.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Settings: change these!
local GAME_PASS_ID = 0
local STAT_NAME = "Coins"

local owners = {}

local function watchCoins(player)
	local stats = player:WaitForChild("leaderstats", 30)
	local coins = stats and stats:WaitForChild(STAT_NAME, 30)
	if not coins then
		return
	end
	task.wait(5) -- let saved coins load first, so loading does not get doubled
	local last = coins.Value
	local adding = false
	coins.Changed:Connect(function(value)
		if adding then
			return -- this change is our own bonus, do not double it again
		end
		local gained = value - last
		if owners[player] and gained > 0 then
			adding = true
			coins.Value = value + gained -- add the same amount again
			adding = false
		end
		last = coins.Value
	end)
end

Players.PlayerAdded:Connect(function(player)
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASS_ID)
	end)
	owners[player] = ok and owns
	watchCoins(player)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
	if bought and passId == GAME_PASS_ID then
		owners[player] = true
	end
end)

Players.PlayerRemoving:Connect(function(player)
	owners[player] = nil
end)
