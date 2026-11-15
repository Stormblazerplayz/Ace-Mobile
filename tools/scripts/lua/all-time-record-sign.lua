-- @title All time record sign
-- @category Leaderboards
-- @kind Script
-- @where Put this Script inside an anchored Part with a flat front (the sign). It watches a leaderstats value (Coins by default).
-- @keywords world record, all time record, highest ever, record holder sign, beat the record
-- @about Remembers the highest score anyone has ever reached in any server, shows it with the holder's name, and announces when someone beats it.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: change this!
local STAT_NAME = "Coins"

local sign = script.Parent
local store = DataStoreService:GetDataStore("AllTimeRecord_v1")
local KEY = STAT_NAME

local surface = Instance.new("SurfaceGui")
surface.Face = Enum.NormalId.Front
surface.Parent = sign
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Color3.fromRGB(40, 20, 10)
label.TextColor3 = Color3.fromRGB(255, 215, 0)
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.Text = "Loading record..."
label.Parent = surface

local record = { value = 0, name = "nobody" }
local function show()
	label.Text = "ALL TIME RECORD\n" .. record.value .. " " .. STAT_NAME .. "\nby " .. record.name
end

local ok, saved = pcall(function()
	return store:GetAsync(KEY)
end)
if ok and type(saved) == "table" then
	record = saved
end
show()

while true do
	task.wait(30)
	for _, player in ipairs(Players:GetPlayers()) do
		local stat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild(STAT_NAME)
		if stat and stat.Value > record.value then
			local newRecord = { value = stat.Value, name = player.DisplayName }
			-- UpdateAsync makes sure another server's higher record is never overwritten
			local saveOk, result = pcall(function()
				return store:UpdateAsync(KEY, function(old)
					if type(old) == "table" and old.value >= newRecord.value then
						return nil
					end
					return newRecord
				end)
			end)
			if saveOk then
				record = result or record
				if record.name == newRecord.name then
					workspace:SetAttribute("Announcement", "")
					workspace:SetAttribute("Announcement", player.DisplayName .. " set a new record!")
				end
				show()
			end
		end
	end
end
