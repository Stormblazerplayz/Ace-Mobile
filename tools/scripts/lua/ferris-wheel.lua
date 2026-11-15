-- @title Ferris wheel motor
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside the wheel Model, with the axle Part named Axle (Anchored, its red X arrow pointing through the middle of the wheel) and every other wheel part welded to a Part named Hub that is NOT anchored.
-- @keywords ferris wheel, big wheel ride, motor spin, hinge motor, theme park wheel, windmill
-- @about Uses a HingeConstraint motor to turn the wheel with real physics, so seats and riders go round with it.

-- Settings: change these numbers!
local SPEED = 0.3 -- turning speed (radians per second, try 0.1 to 2)
local TORQUE = 1e9 -- how strong the motor is

local model = script.Parent
local axle = model:WaitForChild("Axle")
local hub = model:WaitForChild("Hub")
axle.Anchored = true
hub.Anchored = false

-- Attachments at the center of each part; the hinge spins around their X axis
local a0 = Instance.new("Attachment")
a0.Parent = axle
local a1 = Instance.new("Attachment")
a1.Parent = hub
-- Move the hub attachment so it lines up with the axle
a1.WorldCFrame = a0.WorldCFrame

local hinge = Instance.new("HingeConstraint")
hinge.Attachment0 = a0
hinge.Attachment1 = a1
hinge.ActuatorType = Enum.ActuatorType.Motor
hinge.AngularVelocity = SPEED
hinge.MotorMaxTorque = TORQUE
hinge.MotorMaxAcceleration = 1 -- start and stop gently
hinge.Parent = hub

-- Let the server run the physics so it looks the same for everyone
hub:SetNetworkOwner(nil)
