-- @title Spinning disk you can ride
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside a Cylinder Part lying flat (the disk); it does not need to be Anchored.
-- @keywords spinning disk, merry go round, spinning floor ride, rotating platform you stand on, carousel
-- @about The disk spins with a physics motor, so players standing on it get carried around.

-- Settings: change these numbers!
local SPEED = 1 -- radians per second (bigger = faster)

local disk = script.Parent

-- An invisible anchored part under the middle works as the axle
local axle = Instance.new("Part")
axle.Name = "DiskAxle"
axle.Size = Vector3.new(1, 1, 1)
axle.Transparency = 1
axle.CanCollide = false
axle.Anchored = true
axle.CFrame = disk.CFrame
axle.Parent = disk.Parent

-- Point both attachments straight up, so the hinge spins around the up axis
local upwards = CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, Vector3.xAxis)
local a0 = Instance.new("Attachment")
a0.Parent = axle
a0.WorldCFrame = CFrame.new(disk.Position) * upwards
local a1 = Instance.new("Attachment")
a1.Parent = disk
a1.WorldCFrame = a0.WorldCFrame

local motor = Instance.new("HingeConstraint")
motor.Attachment0 = a0
motor.Attachment1 = a1
motor.ActuatorType = Enum.ActuatorType.Motor
motor.AngularVelocity = SPEED
motor.MotorMaxTorque = 1e9
motor.Parent = disk

disk.Anchored = false
disk:SetNetworkOwner(nil)
