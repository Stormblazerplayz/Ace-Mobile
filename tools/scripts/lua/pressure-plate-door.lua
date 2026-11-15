-- @title Pressure plate door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside a Model with two Anchored Parts named Plate (on the floor) and Door.
-- @keywords pressure plate, stand on plate, weight plate, hold the door open, step plate door
-- @about The door stays open only while someone (or something) is standing on the plate.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local DOOR_RISE = 12 -- how far up the door slides

local model = script.Parent
local plate = model:WaitForChild("Plate")
local door = model:WaitForChild("Door")
local closed = door.CFrame
local open = closed + Vector3.new(0, DOOR_RISE, 0)
local plateUp = plate.CFrame
local plateDown = plateUp - Vector3.new(0, plate.Size.Y / 2, 0)

local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { model }

-- Is anything sitting on top of the plate? (players, boxes, anything not anchored)
local function somethingOnPlate()
	local box = plateUp * CFrame.new(0, plate.Size.Y / 2 + 1, 0)
	for _, part in ipairs(workspace:GetPartBoundsInBox(box, Vector3.new(plate.Size.X, 2, plate.Size.Z), params)) do
		if not part.Anchored then
			return true
		end
	end
	return false
end

local isOpen = false
while true do
	task.wait(0.15)
	local pressed = somethingOnPlate()
	if pressed ~= isOpen then
		isOpen = pressed
		TweenService:Create(door, TweenInfo.new(0.5), { CFrame = isOpen and open or closed }):Play()
		plate.CFrame = isOpen and plateDown or plateUp
	end
end
