-- @title Bonus coins for playing with friends
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService (needs a Coins stat, like from the Leaderstats with saving script).
-- @keywords friend bonus, play with friends reward, friends in server, invite friends bonus, friend boost
-- @about Every minute, players get bonus coins for each Roblox friend who is in the same server.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local COINS_PER_FRIEND = 5
local EVERY = 60 -- seconds
local MAX_FRIENDS_COUNTED = 5

-- Count how many of this player's friends are in the server
local function countFriends(player)
	local count = 0
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local ok, isFriend = pcall(function()
				return player:IsFriendsWith(other.UserId)
			end)
			if ok and isFriend then
				count = count + 1
			end
		end
	end
	return math.min(count, MAX_FRIENDS_COUNTED)
end

while true do
	task.wait(EVERY)
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		local friends = countFriends(player)
		player:SetAttribute("FriendsHere", friends) -- a GUI can show this
		if coins and friends > 0 then
			coins.Value = coins.Value + friends * COINS_PER_FRIEND
		end
	end
end
