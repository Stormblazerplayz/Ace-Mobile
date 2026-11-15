-- @title Statue of the number one player
-- @category Leaderboards
-- @kind Script
-- @where Put this Script inside an anchored Part (the statue's stand). It uses the same board as the Global top 10 board script (Wins by default).
-- @keywords top player statue, number one statue, hall of fame, best player avatar, winner statue
-- @about Builds a statue of the number one player of all time on the stand, using their real avatar, and updates it every few minutes.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: change these!
local STAT_NAME = "Wins"
local REFRESH_EVERY = 300

local stand = script.Parent
local store = DataStoreService:GetOrderedDataStore("Global" .. STAT_NAME .. "_v1")
local statue = nil
local shownUserId = nil

local function buildStatue(userId)
	-- CreateHumanoidModelFromUserId makes a copy of someone's avatar
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromUserId(userId)
	end)
	if not ok or not model then
		return
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true -- statues do not move
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local nameOk, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	model.Name = "Statue"
	local _, size = model:GetBoundingBox()
	model:PivotTo(stand.CFrame * CFrame.new(0, stand.Size.Y / 2 + size.Y / 2, 0))
	model.Parent = workspace

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(200, 40)
	sign.StudsOffset = Vector3.new(0, size.Y / 2 + 1, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextStrokeTransparency = 0
	label.Text = "#1 " .. (nameOk and name or "Player")
	label.Parent = sign
	sign.Parent = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	return model
end

while true do
	local ok, page = pcall(function()
		return store:GetSortedAsync(false, 1):GetCurrentPage()
	end)
	local top = ok and page[1]
	local userId = top and tonumber(top.key)
	if userId and userId ~= shownUserId then
		if statue then
			statue:Destroy()
		end
		statue = buildStatue(userId)
		shownUserId = userId
	end
	task.wait(REFRESH_EVERY)
end
