-- @title Crown on the richest player
-- @category Leaderboards
-- @kind Script
-- @where Put this Script in ServerScriptService. It looks at a leaderstats value (Coins by default).
-- @keywords top player crown, number one crown, richest player, leader crown, king of server
-- @about Puts a floating golden crown above the head of whoever has the most coins in the server, and moves it when someone passes them.

local Players = game:GetService("Players")

-- Settings: change this!
local STAT_NAME = "Coins"

local current = nil

local function makeCrown()
	local crown = Instance.new("BillboardGui")
	crown.Name = "LeaderCrown"
	crown.Size = UDim2.fromOffset(60, 60)
	crown.StudsOffset = Vector3.new(0, 3, 0)
	crown.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "#1"
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 210, 40)
	label.TextStrokeTransparency = 0
	label.Parent = crown
	return crown
end

local function richest()
	local best, bestValue = nil, 0
	for _, player in ipairs(Players:GetPlayers()) do
		local stat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild(STAT_NAME)
		if stat and stat.Value > bestValue then
			best, bestValue = player, stat.Value
		end
	end
	return best
end

while true do
	task.wait(2)
	local leader = richest()
	local head = leader and leader.Character and leader.Character:FindFirstChild("Head")
	-- Remove crowns from anyone who is not the leader anymore
	for _, player in ipairs(Players:GetPlayers()) do
		local oldHead = player.Character and player.Character:FindFirstChild("Head")
		local crown = oldHead and oldHead:FindFirstChild("LeaderCrown")
		if crown and player ~= leader then
			crown:Destroy()
		end
	end
	if head and not head:FindFirstChild("LeaderCrown") then
		makeCrown().Parent = head
		if leader ~= current then
			current = leader
			for _, player in ipairs(Players:GetPlayers()) do
				player:SetAttribute("Notice", leader.DisplayName .. " is now #1!")
			end
		end
	end
end
