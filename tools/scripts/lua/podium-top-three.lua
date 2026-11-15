-- @title Podium for the top three
-- @category Leaderboards
-- @kind Script
-- @where Put this Script in ServerScriptService. Make three anchored Parts named Podium1, Podium2 and Podium3 (a tall one in the middle!).
-- @keywords podium, top three players, gold silver bronze, winners podium, first second third
-- @about Shows the names and scores of the top three players in the server floating above the gold, silver and bronze podiums.

local Players = game:GetService("Players")

-- Settings: change this!
local STAT_NAME = "Wins"

local COLORS = { Color3.fromRGB(255, 215, 0), Color3.fromRGB(200, 200, 210), Color3.fromRGB(205, 127, 50) }
local labels = {}

for place = 1, 3 do
	local podium = workspace:WaitForChild("Podium" .. place)
	podium.Color = COLORS[place]
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(220, 70)
	sign.StudsOffset = Vector3.new(0, podium.Size.Y / 2 + 3, 0)
	sign.Parent = podium
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = COLORS[place]
	label.TextStrokeTransparency = 0
	label.Text = "#" .. place
	label.Parent = sign
	labels[place] = label
end

while true do
	-- Make a list of everyone and sort it from highest to lowest
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local stat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild(STAT_NAME)
		if stat then
			table.insert(list, { name = player.DisplayName, value = stat.Value })
		end
	end
	table.sort(list, function(a, b)
		return a.value > b.value
	end)
	for place = 1, 3 do
		local entry = list[place]
		labels[place].Text = entry and ("#" .. place .. " " .. entry.name .. "\n" .. entry.value .. " " .. STAT_NAME) or ("#" .. place)
	end
	task.wait(3)
end
