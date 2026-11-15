-- @title Outfit changing pad
-- @category Players
-- @kind Script
-- @where Put this Script inside an Anchored Part, and put the Roblox user id whose avatar you want to copy below.
-- @keywords outfit pad, change avatar, wear someone's outfit, costume pad, morph into player
-- @about Stepping on the pad dresses your character in the avatar of the user id you choose.

local Players = game:GetService("Players")

-- Settings: change this! (the number in someone's profile link)
local USER_ID = 1 -- 1 is the Roblox account
local COOLDOWN = 3

local pad = script.Parent
local recent = {}

-- Download the outfit once (pcall in case Roblox's website is slow)
local ok, description = pcall(function()
	return Players:GetHumanoidDescriptionFromUserId(USER_ID)
end)
if not ok then
	warn("Could not load outfit: " .. tostring(description))
	return
end

pad.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not player or not humanoid or recent[player] then
		return
	end
	recent[player] = true
	pcall(function()
		humanoid:ApplyDescription(description:Clone())
	end)
	task.delay(COOLDOWN, function()
		recent[player] = nil
	end)
end)
