-- @title Roblox Premium perks
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords premium perk, premium members bonus, premium benefits, membershiptype premium, premium reward
-- @about Players with Roblox Premium get a little speed boost and a Premium attribute other scripts can check.

local Players = game:GetService("Players")

-- Settings: change these!
local PREMIUM_SPEED = 20 -- normal is 16

local function isPremium(player)
	return player.MembershipType == Enum.MembershipType.Premium
end

local function applyPerks(player)
	player:SetAttribute("Premium", isPremium(player))
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and isPremium(player) then
		humanoid.WalkSpeed = PREMIUM_SPEED
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		applyPerks(player)
	end)
	applyPerks(player)
end)

-- Someone bought Premium while playing
Players.PlayerMembershipChanged:Connect(applyPerks)
