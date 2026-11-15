-- @title Fastest times board
-- @category Leaderboards
-- @kind Script
-- @where Put this Script inside an anchored Part (the board). It uses the Best Time value made by the Obby speedrun timer script.
-- @keywords fastest times, speedrun leaderboard, best time board, quickest players, time trial records
-- @about Saves every player's best obby time and shows the 10 fastest times from all servers, quickest at the top.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: change these!
local STAT_NAME = "Best Time"
local REFRESH_EVERY = 60

local board = script.Parent
local store = DataStoreService:GetOrderedDataStore("FastestTimes_v1")

local surface = Instance.new("SurfaceGui")
surface.Face = Enum.NormalId.Front
surface.Parent = board
local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundColor3 = Color3.fromRGB(20, 35, 30)
text.TextColor3 = Color3.new(1, 1, 1)
text.Font = Enum.Font.Code
text.TextScaled = true
text.Parent = surface

while true do
	-- OrderedDataStores only hold whole numbers, so save hundredths of a second (12.34 s = 1234)
	for _, player in ipairs(Players:GetPlayers()) do
		local best = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild(STAT_NAME)
		if best and best.Value > 0 then
			local hundredths = math.floor(best.Value * 100 + 0.5)
			pcall(function()
				store:UpdateAsync(tostring(player.UserId), function(old)
					if old and old <= hundredths then
						return nil -- their saved time is already faster
					end
					return hundredths
				end)
			end)
		end
	end
	-- true = smallest first (fastest times on top)
	local ok, page = pcall(function()
		return store:GetSortedAsync(true, 10):GetCurrentPage()
	end)
	if ok then
		local lines = { "FASTEST TIMES" }
		for rank, entry in ipairs(page) do
			local nameOk, name = pcall(Players.GetNameFromUserIdAsync, Players, tonumber(entry.key))
			table.insert(lines, string.format("%d. %s  %.2fs", rank, nameOk and name or "???", entry.value / 100))
		end
		text.Text = table.concat(lines, "\n")
	end
	task.wait(REFRESH_EVERY)
end
