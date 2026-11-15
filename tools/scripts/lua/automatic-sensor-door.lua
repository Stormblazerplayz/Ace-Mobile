-- @title Double doors that open when you walk up
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside a Model with two Anchored Parts named LeftDoor and RightDoor that close in the middle.
-- @keywords sensor door, supermarket doors, double doors, doors open when near, motion sensor doors
-- @about Like a supermarket: both doors slide apart when a player comes close and close when everyone leaves.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local SENSE_DISTANCE = 12
local SLIDE_TIME = 0.5

local model = script.Parent
local left = model:WaitForChild("LeftDoor")
local right = model:WaitForChild("RightDoor")
local center = (left.Position + right.Position) / 2

-- Work out the open spots: each door slides away from the middle by its own width
local function openCFrame(door)
	local away = (door.Position - center).Unit
	return door.CFrame + away * door.Size.X
end
local doors = {
	{ part = left, closed = left.CFrame, open = openCFrame(left) },
	{ part = right, closed = right.CFrame, open = openCFrame(right) },
}

local function someoneNear()
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - center).Magnitude < SENSE_DISTANCE then
			return true
		end
	end
	return false
end

local isOpen = false
while true do
	task.wait(0.2)
	local shouldOpen = someoneNear()
	if shouldOpen ~= isOpen then
		isOpen = shouldOpen
		for _, door in ipairs(doors) do
			local goal = isOpen and door.open or door.closed
			TweenService:Create(door.part, TweenInfo.new(SLIDE_TIME), { CFrame = goal }):Play()
		end
	end
end
