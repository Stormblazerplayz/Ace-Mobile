-- @title Daily or weekly top board
-- @category Leaderboards
-- @kind Script
-- @where Put this Script inside an anchored Part (the board). It counts how much of a leaderstats value (like Coins) players EARN today or this week.
-- @keywords daily leaderboard, weekly leaderboard, resets every day, top this week, fresh leaderboard
-- @about A top 10 board that starts fresh every day (or every week), so new players can get to the top too.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: change these!
local STAT_NAME = "Coins"
local PERIOD = "Daily" -- "Daily" or "Weekly"

local board = script.Parent

-- Each day (or week) gets its own store name, so the board resets by itself
local function periodKey()
	local day = math.floor(os.time() / 86400)
	if PERIOD == "Weekly" then
		return "Week" .. math.floor(day / 7)
	end
	return "Day" .. day
end

local surface = Instance.new("SurfaceGui")
surface.Face = Enum.NormalId.Front
surface.Parent = board
local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
text.TextColor3 = Color3.new(1, 1, 1)
text.Font = Enum.Font.GothamBold
text.TextScaled = true
text.Parent = surface

-- Remember each player's stat when they join, so we only count what they earn
local startValue = {}
local earned = {}
Players.PlayerAdded:Connect(function(player)
	local stat = player:WaitForChild("leaderstats"):WaitForChild(STAT_NAME, 10)
	if not stat then
		return
	end
	startValue[player] = stat.Value
	stat.Changed:Connect(function(value)
		if value < startValue[player] then
			startValue[player] = value -- they spent some; do not count that as negative
		end
		earned[player] = (earned[player] or 0) + math.max(0, value - startValue[player])
		startValue[player] = value
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	startValue[player] = nil
end)

while true do
	task.wait(60)
	local store = DataStoreService:GetOrderedDataStore(STAT_NAME .. PERIOD .. "_" .. periodKey())
	for player, amount in pairs(earned) do
		earned[player] = nil
		pcall(function()
			store:IncrementAsync(tostring(player.UserId), math.floor(amount))
		end)
	end
	local ok, page = pcall(function()
		return store:GetSortedAsync(false, 10):GetCurrentPage()
	end)
	if ok then
		local lines = { PERIOD .. " top " .. STAT_NAME }
		for rank, entry in ipairs(page) do
			local nameOk, name = pcall(Players.GetNameFromUserIdAsync, Players, tonumber(entry.key))
			table.insert(lines, rank .. ". " .. (nameOk and name or "???") .. "  " .. entry.value)
		end
		text.Text = table.concat(lines, "\n")
	end
end
