-- @title Simple airplane
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a plane Model with a VehicleSeat facing the front of the plane. Use a long, flat open area as a runway.
-- @keywords airplane, fly a plane, plane controls, aircraft, pilot seat
-- @about Hold W to speed up and take off, S to slow down, and A or D to bank and turn; slow planes sink back to the ground.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these!
local MAX_SPEED = 120
local TAKEOFF_SPEED = 50
local ACCELERATION = 20
local TURN_RATE = 0.8

local plane = script.Parent
local seat = plane:FindFirstChildWhichIsA("VehicleSeat", true)

local attachment = Instance.new("Attachment")
attachment.Parent = seat
local mover = Instance.new("LinearVelocity")
mover.Attachment0 = attachment
mover.RelativeTo = Enum.ActuatorRelativeTo.World
mover.MaxForce = 0
mover.Parent = seat
local align = Instance.new("AlignOrientation")
align.Mode = Enum.OrientationAlignmentMode.OneAttachment
align.Attachment0 = attachment
align.MaxTorque = 0
align.Responsiveness = 10
align.Parent = seat

local speed = 0
local heading = select(2, seat.CFrame:ToEulerAnglesYXZ())

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	local humanoid = seat.Occupant
	local player = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
	if player then
		pcall(seat.SetNetworkOwner, seat, player) -- pcall: fails safely if the car is anchored
	else
		pcall(seat.SetNetworkOwnershipAuto, seat)
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	if not seat.Occupant then
		speed = math.max(speed - ACCELERATION * deltaTime * 2, 0)
		if speed == 0 then
			mover.MaxForce = 0
			align.MaxTorque = 0
			return
		end
	else
		speed = math.clamp(speed + seat.ThrottleFloat * ACCELERATION * deltaTime, 0, MAX_SPEED)
	end
	mover.MaxForce = 1e6
	align.MaxTorque = 1e6
	heading -= seat.SteerFloat * TURN_RATE * deltaTime
	-- Fast planes nose up and climb; slow planes nose down and sink
	local lift = (speed - TAKEOFF_SPEED) / MAX_SPEED -- below 0 when too slow
	local pitch = math.clamp(lift, -0.3, 0.3)
	local roll = -seat.SteerFloat * 0.5
	align.CFrame = CFrame.Angles(0, heading, 0) * CFrame.Angles(pitch, 0, roll)
	local forward = CFrame.Angles(0, heading, 0) * CFrame.Angles(pitch, 0, 0)
	local velocity = forward.LookVector * speed
	if speed < TAKEOFF_SPEED then
		velocity += Vector3.new(0, -20, 0) -- not fast enough: gravity wins
	end
	mover.VectorVelocity = velocity
end)
