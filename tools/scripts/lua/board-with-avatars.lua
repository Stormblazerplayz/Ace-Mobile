-- @title Top 5 board with avatar faces
-- @category Leaderboards
-- @kind Script
-- @where Put this Script inside a big anchored Part. It reads the same board the Global top 10 board script saves to (Wins by default), so use that script too.
-- @keywords avatar leaderboard, headshot board, player faces board, top five faces, picture leaderboard
-- @about Shows the top 5 players of all time with a picture of each player's avatar face next to their name and score.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: change these!
local STAT_NAME = "Wins"
local REFRESH_EVERY = 120

local board = script.Parent
local store = DataStoreService:GetOrderedDataStore("Global" .. STAT_NAME .. "_v1")

local surface = Instance.new("SurfaceGui")
surface.Face = Enum.NormalId.Front
surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
surface.PixelsPerStud = 40
surface.Parent = board
local holder = Instance.new("Frame")
holder.Size = UDim2.fromScale(1, 1)
holder.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
holder.Parent = surface
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = holder

local function addRow(rank, userId, name, value)
	local row = Instance.new("Frame")
	row.LayoutOrder = rank
	row.Size = UDim2.fromScale(1, 0.2)
	row.BackgroundTransparency = rank % 2 == 0 and 0.85 or 1
	row.Parent = holder
	local face = Instance.new("ImageLabel")
	face.Size = UDim2.fromScale(0.2, 1)
	face.SizeConstraint = Enum.SizeConstraint.RelativeYY
	face.BackgroundTransparency = 1
	-- rbxthumb gives a picture of any player's avatar from their UserId
	face.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
	face.Parent = row
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromScale(0.25, 0)
	label.Size = UDim2.fromScale(0.75, 1)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "#" .. rank .. " " .. name .. "  (" .. value .. ")"
	label.Parent = row
end

while true do
	local ok, page = pcall(function()
		return store:GetSortedAsync(false, 5):GetCurrentPage()
	end)
	if ok then
		for _, child in ipairs(holder:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		for rank, entry in ipairs(page) do
			local userId = tonumber(entry.key)
			local nameOk, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
			addRow(rank, userId, nameOk and name or "???", entry.value)
		end
	end
	task.wait(REFRESH_EVERY)
end
