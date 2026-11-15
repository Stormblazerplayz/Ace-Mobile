-- @title Redeem codes (server)
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService (it makes a RemoteFunction named RedeemCode; use the Redeem codes box script for the GUI).
-- @keywords redeem codes, promo codes, twitter codes, enter a code for coins, code rewards
-- @about Checks codes players type in, gives the reward once per player, and saves which codes they used.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: your codes (write them in CAPITALS) and how many coins each gives
local CODES = {
	["RELEASE"] = 100,
	["THANKS1K"] = 500,
}

local store = DataStoreService:GetDataStore("UsedCodes_v1")
local remote = ReplicatedStorage:FindFirstChild("RedeemCode") or Instance.new("RemoteFunction")
remote.Name = "RedeemCode"
remote.Parent = ReplicatedStorage

local lastTry = {}

remote.OnServerInvoke = function(player, code)
	if typeof(code) ~= "string" or #code > 30 then
		return false, "Invalid code"
	end
	if os.clock() - (lastTry[player] or 0) < 2 then
		return false, "Slow down!"
	end
	lastTry[player] = os.clock()

	code = string.upper(code:gsub("%s", "")) -- ignore spaces and capitals
	local reward = CODES[code]
	if not reward then
		return false, "That code does not exist"
	end

	-- Save the code as used (UpdateAsync makes sure two servers cannot both give it)
	local alreadyUsed = false
	local ok = pcall(function()
		store:UpdateAsync("Player_" .. player.UserId, function(used)
			used = used or {}
			if used[code] then
				alreadyUsed = true
				return nil
			end
			used[code] = true
			return used
		end)
	end)
	if not ok then
		return false, "Try again in a moment"
	elseif alreadyUsed then
		return false, "You already used that code"
	end

	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		coins.Value = coins.Value + reward
	end
	return true, "+" .. reward .. " coins!"
end

Players.PlayerRemoving:Connect(function(player)
	lastTry[player] = nil
end)
