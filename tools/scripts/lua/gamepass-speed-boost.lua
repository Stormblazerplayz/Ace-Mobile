-- @title Game pass speed boost
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService and put your game pass id below.
-- @keywords gamepass speed, game pass perk, buy speed, user owns gamepass, vip speed boost
-- @about Players who own your game pass run faster, and it works right away if they buy it during the game.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Settings: change these!
local GAME_PASS_ID = 0 -- your game pass id from the Creator Hub
local BOOST_SPEED = 32

local owners = {}

local function giveSpeed(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if owners[player] and humanoid then
		humanoid.WalkSpeed = BOOST_SPEED
	end
end

Players.PlayerAdded:Connect(function(player)
	-- Ask Roblox if they own the pass (pcall because it uses the internet)
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASS_ID)
	end)
	owners[player] = ok and owns
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		giveSpeed(player)
	end)
	giveSpeed(player)
end)

-- Bought it in game? Give the boost now
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if purchased and passId == GAME_PASS_ID then
		owners[player] = true
		giveSpeed(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	owners[player] = nil
end)
