-- @title Car spawner pad
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside an anchored Part (the spawn pad), and put your car Model in ServerStorage named in CAR_NAME.
-- @keywords car spawner, spawn vehicle, get a car, vehicle pad, car dealer
-- @about Hold E at the pad to spawn your own car next to it; spawning again removes your old car first.

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Settings: change these!
local CAR_NAME = "Car"
local COOLDOWN = 5

local pad = script.Parent
local template = ServerStorage:WaitForChild(CAR_NAME)
local spawned = {} -- spawned[player] = their car
local lastSpawn = {}

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Spawn car"
prompt.ObjectText = CAR_NAME
prompt.HoldDuration = 0.5
prompt.Parent = pad

prompt.Triggered:Connect(function(player)
	if os.clock() - (lastSpawn[player] or 0) < COOLDOWN then
		return
	end
	lastSpawn[player] = os.clock()
	if spawned[player] then
		spawned[player]:Destroy() -- only one car each
	end
	local car = template:Clone()
	car.Name = player.Name .. "'s " .. CAR_NAME
	car:SetAttribute("Owner", player.UserId) -- the Car owner lock script reads this
	-- Place it in front of the pad, a bit above the ground
	car:PivotTo(pad.CFrame * CFrame.new(0, 4, -12))
	car.Parent = workspace
	spawned[player] = car
end)

Players.PlayerRemoving:Connect(function(player)
	if spawned[player] then
		spawned[player]:Destroy()
		spawned[player] = nil
	end
	lastSpawn[player] = nil
end)
