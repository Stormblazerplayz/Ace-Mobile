-- @title Conveyor belt
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside a flat Part; it pushes players toward the part's Front side (spin the part around to change the direction).
-- @keywords conveyor belt, treadmill, moving floor, floor that pushes you, push part
-- @about Pushes anything standing on the part along, like a conveyor belt.

-- Settings: change this number!
local SPEED = 10 -- studs per second (bigger = faster, negative = backwards)

local belt = script.Parent
belt.Anchored = true -- the belt itself stays still

-- The belt "pretends" to move, so things on top slide along
local function updateBelt()
	belt.AssemblyLinearVelocity = belt.CFrame.LookVector * SPEED
end

updateBelt()
-- If you turn the part around while playing, the push direction follows
belt:GetPropertyChangedSignal("CFrame"):Connect(updateBelt)
