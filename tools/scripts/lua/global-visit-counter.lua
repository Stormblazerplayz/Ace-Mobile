-- @title Total visits sign
-- @category Saving data
-- @kind Script
-- @where Put this Script inside a Part that has a SurfaceGui with a TextLabel in it.
-- @keywords visit counter, total joins, global counter, how many players joined, all time joins sign
-- @about Counts every player that has ever joined your game (across all servers) and shows the total on a sign.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local sign = script.Parent
local label = sign:FindFirstChildWhichIsA("TextLabel", true)
local store = DataStoreService:GetDataStore("GlobalStats_v1")
local KEY = "TotalJoins"

local pendingJoins = 0 -- joins in this server we still need to add

local function show(total)
	if label then
		label.Text = "Total joins: " .. tostring(total)
	end
end

Players.PlayerAdded:Connect(function()
	pendingJoins += 1
end)

-- Every 60 seconds, add our joins to the shared total in one go
-- (doing it once a minute is kinder to DataStore limits than once per player)
local function flush()
	local adding = pendingJoins
	local ok, total = pcall(function()
		return store:IncrementAsync(KEY, adding)
	end)
	if ok then
		pendingJoins -= adding
		show(total)
	end
end

game:BindToClose(flush)

-- Show the starting number
local ok, total = pcall(function()
	return store:GetAsync(KEY)
end)
show(ok and total or 0)

while true do
	task.wait(60)
	flush()
end
