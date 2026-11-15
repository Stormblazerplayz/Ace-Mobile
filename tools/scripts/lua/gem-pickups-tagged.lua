-- @title Gems (second currency) pickups
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService, then give your gem Parts the tag Gem (Tag Editor in the Properties window).
-- @keywords gems, second currency, gem pickup, collect gems, diamonds currency, tagged pickups
-- @about Adds a Gems stat, and every part tagged Gem gives gems when touched and comes back after a while.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Settings: change these numbers!
local GEMS_EACH = 1 -- or give a gem part a number Attribute named Amount
local RESPAWN_TIME = 20

Players.PlayerAdded:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local gems = Instance.new("IntValue")
	gems.Name = "Gems"
	gems.Parent = stats
end)

local function setupGem(gem)
	if not gem:IsA("BasePart") then
		return
	end
	local taken = false
	gem.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local stats = player and player:FindFirstChild("leaderstats")
		local gems = stats and stats:FindFirstChild("Gems")
		if taken or not gems then
			return
		end
		taken = true
		gems.Value = gems.Value + (gem:GetAttribute("Amount") or GEMS_EACH)
		gem.Transparency = 1
		gem.CanTouch = false
		task.wait(RESPAWN_TIME)
		gem.Transparency = 0
		gem.CanTouch = true
		taken = false
	end)
end

-- Works for gems that exist now AND gems added later
for _, gem in ipairs(CollectionService:GetTagged("Gem")) do
	setupGem(gem)
end
CollectionService:GetInstanceAddedSignal("Gem"):Connect(setupGem)
