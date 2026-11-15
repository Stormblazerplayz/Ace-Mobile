-- @title Flipper arm that launches you
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside a flat unanchored Part (the flipper) and add an Anchored Part named FlipperPivot at one end, turned so its red X arrow runs along the hinge line.
-- @keywords flipper, launch flipper, pinball flipper, catapult arm, flip players into the air
-- @about Every few seconds the flipper snaps up with a physics hinge and flings anything standing on it.

-- Settings: change these numbers!
local FLIP_ANGLE = 60 -- degrees it flips up (use -60 if it flips the wrong way)
local FLIP_SPEED = 25 -- radians per second, very fast
local WAIT_TIME = 3 -- seconds between flips

local flipper = script.Parent
local pivot = flipper.Parent:WaitForChild("FlipperPivot")
pivot.Anchored = true
flipper.Anchored = false

local a0 = Instance.new("Attachment")
a0.Parent = pivot
local a1 = Instance.new("Attachment")
a1.Parent = flipper
a1.WorldCFrame = a0.WorldCFrame

local hinge = Instance.new("HingeConstraint")
hinge.Attachment0 = a0
hinge.Attachment1 = a1
hinge.ActuatorType = Enum.ActuatorType.Servo
hinge.ServoMaxTorque = 1e10
hinge.AngularSpeed = FLIP_SPEED
hinge.TargetAngle = 0
hinge.Parent = flipper

flipper:SetNetworkOwner(nil)

while true do
	task.wait(WAIT_TIME)
	hinge.AngularSpeed = FLIP_SPEED
	hinge.TargetAngle = FLIP_ANGLE -- SNAP up!
	task.wait(0.5)
	hinge.AngularSpeed = 2 -- come back down slowly
	hinge.TargetAngle = 0
end
