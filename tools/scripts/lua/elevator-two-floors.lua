-- @title Elevator between two floors
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside the elevator floor Part (it can be Anchored, the script fixes it) at the bottom floor.
-- @keywords elevator, lift, go up and down, elevator platform, ride to the top floor
-- @about Press E on the elevator to ride it up or down; it is physics based so players ride smoothly.

-- Settings: change these numbers!
local HEIGHT = 30 -- how far up the top floor is (studs)
local SPEED = 8 -- studs per second

local platform = script.Parent

-- An invisible anchored part holds the "rail" the platform slides on
local base = Instance.new("Part")
base.Name = "ElevatorBase"
base.Size = Vector3.new(1, 1, 1)
base.Transparency = 1
base.CanCollide = false
base.Anchored = true
base.CFrame = platform.CFrame
base.Parent = platform.Parent

-- Turn the attachments so their main (X) axis points straight up
local a0 = Instance.new("Attachment")
a0.CFrame = CFrame.Angles(0, 0, math.rad(90))
a0.Parent = base
local a1 = Instance.new("Attachment")
a1.CFrame = CFrame.Angles(0, 0, math.rad(90))
a1.Parent = platform

-- A PrismaticConstraint slides along one line; Servo means "go to TargetPosition"
local slider = Instance.new("PrismaticConstraint")
slider.Attachment0 = a0
slider.Attachment1 = a1
slider.ActuatorType = Enum.ActuatorType.Servo
slider.Speed = SPEED
slider.ServoMaxForce = 1e8 -- strong enough to lift lots of players
slider.TargetPosition = 0
slider.Parent = platform

platform.Anchored = false
platform:SetNetworkOwner(nil)

-- Press E to go up or down
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Go up"
prompt.ObjectText = "Elevator"
prompt.Parent = platform

prompt.Triggered:Connect(function()
	if slider.TargetPosition == 0 then
		slider.TargetPosition = HEIGHT
		prompt.ActionText = "Go down"
	else
		slider.TargetPosition = 0
		prompt.ActionText = "Go up"
	end
end)
