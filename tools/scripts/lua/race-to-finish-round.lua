-- @title Race to the finish
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService. Add a Part named RaceStart (start line) and a Part named RaceFinish (finish line) to Workspace.
-- @keywords race round, race placings, first place second place, racing minigame, race results
-- @about Lines everyone up, counts down, then gives places (1st, 2nd, 3rd) as racers touch the finish line, with coins for the top three.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local RACE_TIME = 90
local PRIZES = { 100, 50, 25 } -- coins for 1st, 2nd, 3rd

local startPart = workspace:WaitForChild("RaceStart")
local finishPart = workspace:WaitForChild("RaceFinish")
local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local racing = false
local finished = {}

finishPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not racing or not player or table.find(finished, player) then
		return
	end
	table.insert(finished, player)
	local place = #finished
	status.Value = player.Name .. " finished #" .. place .. "!"
	local prize = PRIZES[place]
	local stats = player:FindFirstChild("leaderstats")
	if prize and stats and stats:FindFirstChild("Coins") then
		stats.Coins.Value += prize
		player:SetAttribute("Notice", "Place #" .. place .. "! +" .. prize .. " coins")
	end
end)

while true do
	for t = 15, 1, -1 do
		status.Value = "Race starts in " .. t
		task.wait(1)
	end
	-- Line everyone up at the start and freeze them
	local racers = {}
	for i, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			character:PivotTo(startPart.CFrame * CFrame.new((i - 1) * 4, 4, 0))
			humanoid.WalkSpeed = 0
			table.insert(racers, humanoid)
		end
	end
	workspace:SetAttribute("Countdown", 3) -- the Big countdown script shows 3 2 1 GO
	task.wait(3)
	workspace:SetAttribute("Countdown", 0)
	finished = {}
	racing = true
	for _, humanoid in ipairs(racers) do
		if humanoid.Parent then
			humanoid.WalkSpeed = 16
		end
	end
	for t = RACE_TIME, 1, -1 do
		if #finished >= #racers then
			break
		end
		task.wait(1)
	end
	racing = false
	status.Value = "Race over!"
	task.wait(4)
end
