-- @title Drivable car with hinge wheels
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside your car Model. The car needs a VehicleSeat, back wheels attached with HingeConstraints named DriveLeft and DriveRight, and front wheels on HingeConstraints named SteerLeft and SteerRight (on a steering part).
-- @keywords drive car, hinge constraint car, vehicle seat, motor wheels, steering wheels
-- @about Reads W, A, S, D from the VehicleSeat to spin the back wheels and turn the front wheels, so the car really drives.

local Players = game:GetService("Players")

-- Settings: change these!
local MAX_SPEED = 60 -- studs per second
local WHEEL_RADIUS = 1.5 -- half your wheel's size
local TURN_ANGLE = 30 -- degrees the front wheels turn
local MOTOR_TORQUE = 10000
local FLIP_LEFT = -1 -- if one side spins backwards, change this to 1

local car = script.Parent
local seat = car:FindFirstChildWhichIsA("VehicleSeat", true)
local driveLeft = car:FindFirstChild("DriveLeft", true)
local driveRight = car:FindFirstChild("DriveRight", true)
local steerLeft = car:FindFirstChild("SteerLeft", true)
local steerRight = car:FindFirstChild("SteerRight", true)

-- Make the hinges the right kind
for _, motor in ipairs({ driveLeft, driveRight }) do
	motor.ActuatorType = Enum.ActuatorType.Motor
	motor.MotorMaxTorque = MOTOR_TORQUE
end
for _, servo in ipairs({ steerLeft, steerRight }) do
	servo.ActuatorType = Enum.ActuatorType.Servo
	servo.ServoMaxTorque = MOTOR_TORQUE
	servo.AngularSpeed = 5
end

-- Give the driver control of the car's physics so it feels smooth for them
seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	local humanoid = seat.Occupant
	local player = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
	if player then
		pcall(seat.SetNetworkOwner, seat, player) -- pcall: fails safely if the car is anchored
	else
		pcall(seat.SetNetworkOwnershipAuto, seat)
	end
end)

local function update()
	-- ThrottleFloat: 1 = W, -1 = S. SteerFloat: -1 = A, 1 = D
	local spin = seat.ThrottleFloat * MAX_SPEED / WHEEL_RADIUS
	if car:GetAttribute("OutOfFuel") then
		spin = 0 -- the fuel script says the tank is empty
	end
	driveLeft.AngularVelocity = spin * FLIP_LEFT
	driveRight.AngularVelocity = -spin * FLIP_LEFT
	local angle = seat.SteerFloat * TURN_ANGLE
	steerLeft.TargetAngle = angle
	steerRight.TargetAngle = angle
end
seat:GetPropertyChangedSignal("ThrottleFloat"):Connect(update)
seat:GetPropertyChangedSignal("SteerFloat"):Connect(update)
car:GetAttributeChangedSignal("OutOfFuel"):Connect(update)
update()
