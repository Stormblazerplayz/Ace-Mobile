-- @title King of the hill
-- @category Game rounds
-- @kind Script
-- @where Put this Script inside an anchored Part that marks the hill zone (make it see-through and CanCollide off, big enough to stand in).
-- @keywords king of the hill, hold the zone, capture point, hill control, stand on hill points
-- @about Whoever stands alone on the hill gets a point every second; the first to reach the goal wins and scores reset.

local Players = game:GetService("Players")

-- Settings: change these!
local POINTS_TO_WIN = 60
local STAT_NAME = "Wins"

local zone = script.Parent
local points = {} -- points[player] = number

local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Include

local function playersOnHill()
	local characters = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(characters, player.Character)
		end
	end
	params.FilterDescendantsInstances = characters
	local found = {}
	for _, part in ipairs(workspace:GetPartsInPart(zone, params)) do
		local player = Players:GetPlayerFromCharacter(part.Parent)
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if player and humanoid and humanoid.Health > 0 then
			found[player] = true
		end
	end
	return found
end

Players.PlayerRemoving:Connect(function(player)
	points[player] = nil
end)

while true do
	task.wait(1)
	local onHill = playersOnHill()
	local list = {}
	for player in pairs(onHill) do
		table.insert(list, player)
	end
	if #list == 1 then
		local king = list[1]
		points[king] = (points[king] or 0) + 1
		king:SetAttribute("HillPoints", points[king]) -- a GUI can show this
		zone.Color = Color3.fromRGB(255, 200, 40)
		if points[king] >= POINTS_TO_WIN then
			local stats = king:FindFirstChild("leaderstats")
			local stat = stats and stats:FindFirstChild(STAT_NAME)
			if stat then
				stat.Value += 1
			end
			for _, player in ipairs(Players:GetPlayers()) do
				player:SetAttribute("Notice", king.Name .. " is King of the Hill!")
				player:SetAttribute("HillPoints", 0)
			end
			points = {}
		end
	elseif #list > 1 then
		zone.Color = Color3.fromRGB(220, 60, 60) -- contested: nobody scores
	else
		zone.Color = Color3.fromRGB(200, 200, 200)
	end
end
