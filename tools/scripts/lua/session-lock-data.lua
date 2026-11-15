-- @title Stop data copying between servers
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService (use it instead of other coin saving scripts).
-- @keywords session lock, data duping fix, server hopping save, lock player data, duplication protection
-- @about Locks a player's save while they are in a server so a second server cannot load old coins at the same time (this stops item and coin duping).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("LockedCoins_v1")
local LOCK_TIMEOUT = 300 -- seconds; a lock older than this is from a crashed server
local loaded = {}

-- Try to take the lock. Returns the saved data if we got it.
local function claim(player)
	local key = "Player_" .. player.UserId
	for _ = 1, 5 do
		local gotLock = false
		local ok, data = pcall(function()
			return store:UpdateAsync(key, function(old)
				old = type(old) == "table" and old or { Coins = 0 }
				local lockedByOther = old.Lock and old.Lock ~= game.JobId and os.time() - (old.LockTime or 0) < LOCK_TIMEOUT
				if lockedByOther then
					return nil -- do not change anything, someone else has it
				end
				old.Lock = game.JobId
				old.LockTime = os.time()
				gotLock = true
				return old
			end)
		end)
		if ok and gotLock then
			return data
		end
		task.wait(5) -- the other server is probably still saving; try again
	end
	return nil
end

Players.PlayerAdded:Connect(function(player)
	local data = claim(player)
	if not data then
		player:Kick("Your data is still saving in another server. Please rejoin in a minute!")
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins or 0
	coins.Parent = leaderstats
	leaderstats.Parent = player
	loaded[player] = true
end)

local function save(player, release)
	if not loaded[player] then
		return
	end
	local coins = player.leaderstats.Coins.Value
	pcall(function()
		store:UpdateAsync("Player_" .. player.UserId, function(old)
			old = type(old) == "table" and old or {}
			if old.Lock and old.Lock ~= game.JobId then
				return nil -- another server owns it now; never overwrite
			end
			old.Coins = coins
			old.Lock = (not release) and game.JobId or nil
			old.LockTime = os.time()
			return old
		end)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	save(player, true) -- save and unlock
	loaded[player] = nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player, true)
	end
	task.wait(3)
end)
while true do
	task.wait(120)
	for player in pairs(loaded) do
		task.spawn(save, player, false) -- autosave keeps the lock fresh
	end
end
