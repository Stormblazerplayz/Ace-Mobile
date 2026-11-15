-- @title Auto clicker game pass
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService and put your game pass id below (works with the Click to get stronger tool).
-- @keywords auto clicker, auto click gamepass, auto train, idle gains, automatic clicking
-- @about Players who own the pass gain Strength automatically every second, as if they were clicking.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Settings: change these!
local GAME_PASS_ID = 0
local STAT_NAME = "Strength"
local GAIN_PER_SECOND = 1

local owners = {}

Players.PlayerAdded:Connect(function(player)
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASS_ID)
	end)
	owners[player] = ok and owns or nil
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
	if bought and passId == GAME_PASS_ID then
		owners[player] = true
	end
end)

Players.PlayerRemoving:Connect(function(player)
	owners[player] = nil
end)

while true do
	task.wait(1)
	for player in pairs(owners) do
		local stats = player:FindFirstChild("leaderstats")
		local stat = stats and stats:FindFirstChild(STAT_NAME)
		local rebirths = stats and stats:FindFirstChild("Rebirths")
		if stat then
			local multiplier = (1 + (rebirths and rebirths.Value or 0)) * (player:GetAttribute("Multiplier") or 1)
			stat.Value += GAIN_PER_SECOND * multiplier
		end
	end
end
