-- @title Global top 10 board
-- @category Leaderboards
-- @kind Script
-- @where Put this Script inside a big anchored Part (the board). Players need a leaderstats value named in STAT_NAME (Wins by default). Turn on Studio Access to API Services to test.
-- @keywords global leaderboard, top 10 board, all servers leaderboard, ordered datastore, best players sign
-- @about Shows the top 10 players of all time from every server on a board in your world, refreshing every minute.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: change these!
local STAT_NAME = "Wins"
local TITLE = "Top Winners"
local REFRESH_EVERY = 60

local board = script.Parent
-- OrderedDataStores can sort numbers, so we can ask "who is the highest?"
local store = DataStoreService:GetOrderedDataStore("Global" .. STAT_NAME .. "_v1")

local surface = Instance.new("SurfaceGui")
surface.Face = Enum.NormalId.Front
surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
surface.PixelsPerStud = 40
surface.Parent = board
local list = Instance.new("Frame")
list.Size = UDim2.fromScale(1, 1)
list.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
list.Parent = surface
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function row(order, text, color)
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.Size = UDim2.fromScale(1, 1 / 11)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = list
end

local MEDALS = { Color3.fromRGB(255, 215, 0), Color3.fromRGB(200, 200, 210), Color3.fromRGB(205, 127, 50) }

local function refresh()
	-- First save everyone in this server
	for _, player in ipairs(Players:GetPlayers()) do
		local stat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild(STAT_NAME)
		if stat then
			pcall(function()
				store:SetAsync(tostring(player.UserId), math.floor(stat.Value))
			end)
		end
	end
	-- Then read the top 10 (false = biggest first)
	local ok, page = pcall(function()
		return store:GetSortedAsync(false, 10):GetCurrentPage()
	end)
	if not ok then
		return
	end
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	row(0, TITLE, Color3.fromRGB(120, 200, 255))
	for rank, entry in ipairs(page) do
		local nameOk, name = pcall(function()
			return Players:GetNameFromUserIdAsync(tonumber(entry.key))
		end)
		row(rank, rank .. ". " .. (nameOk and name or "???") .. "  " .. entry.value, MEDALS[rank])
	end
end

while true do
	refresh()
	task.wait(REFRESH_EVERY)
end
