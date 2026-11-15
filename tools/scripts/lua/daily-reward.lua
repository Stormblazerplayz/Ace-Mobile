-- @title Daily reward
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService (needs a Coins stat; turn on Studio Access to API Services to test).
-- @keywords daily reward, daily login bonus, come back tomorrow, free coins every day, daily gift
-- @about Gives players free coins once every 24 hours when they join, and remembers it with a DataStore.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: change these numbers!
local REWARD = 100
local WAIT_HOURS = 24

local store = DataStoreService:GetDataStore("DailyReward_v1")

Players.PlayerAdded:Connect(function(player)
	local key = "Player_" .. player.UserId
	local now = os.time()
	local gotReward = false

	-- UpdateAsync safely reads and writes in one go
	local ok, err = pcall(function()
		store:UpdateAsync(key, function(lastClaim)
			if lastClaim == nil or now - lastClaim >= WAIT_HOURS * 3600 then
				gotReward = true
				return now -- save the new claim time
			end
			gotReward = false
			return nil -- returning nil means "do not change anything"
		end)
	end)
	if not ok then
		warn("Daily reward check failed: " .. tostring(err))
		return
	end

	if gotReward then
		task.wait(5) -- give your saving script time to load their coins first
		local stats = player:WaitForChild("leaderstats", 10)
		local coins = stats and stats:WaitForChild("Coins", 10)
		if coins then
			coins.Value = coins.Value + REWARD
			player:SetAttribute("DailyRewardMessage", "Daily reward: +" .. REWARD .. " coins!")
		end
	end
end)
