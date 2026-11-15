-- @title Random map each round
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService, and put each map as a Model in a Folder named Maps in ServerStorage. Each map needs a Part named MapSpawn inside it.
-- @keywords random map, map rotation, load map, map folder, change map each round
-- @about Picks a random map from ServerStorage, puts it in the world, sends everyone onto it, then removes it when the round ends.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local LOBBY_TIME = 15
local ROUND_TIME = 60

local maps = ServerStorage:WaitForChild("Maps")
local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local lastMap = nil

local function pickMap()
	local list = maps:GetChildren()
	if #list == 0 then
		return nil
	end
	local choice
	repeat
		choice = list[math.random(1, #list)]
	until choice ~= lastMap or #list == 1 -- try not to play the same map twice in a row
	lastMap = choice
	return choice
end

while true do
	for t = LOBBY_TIME, 1, -1 do
		status.Value = "Next map in " .. t
		task.wait(1)
	end
	local chosen = pickMap()
	if not chosen then
		status.Value = "Add maps to ServerStorage.Maps!"
		task.wait(5)
		continue
	end
	local map = chosen:Clone()
	map.Name = "CurrentMap"
	map.Parent = workspace
	local spawnPart = map:FindFirstChild("MapSpawn", true)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character and spawnPart then
			-- Spread players out a little so they do not land on each other
			local offset = Vector3.new(math.random(-6, 6), 4, math.random(-6, 6))
			character:PivotTo(CFrame.new(spawnPart.Position + offset))
		end
	end
	for t = ROUND_TIME, 1, -1 do
		status.Value = chosen.Name .. ": " .. t
		task.wait(1)
	end
	status.Value = "Round over!"
	map:Destroy()
	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter() -- back to the lobby spawn
	end
end
