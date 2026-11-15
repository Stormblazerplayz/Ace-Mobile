-- @title Helicopter
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a helicopter Model with a VehicleSeat facing forward.
-- @keywords helicopter, chopper, hover flight, rotor blades, fly up and hover
-- @about When someone sits in the pilot seat the helicopter lifts off to cruising height; W and S fly forward and back, A and D turn, and it lands when empty.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these!
local CRUISE_HEIGHT = 60 -- studs above where it took off
local SPEED = 50
local TURN_SPEED = 1.2

local heli = script.Parent
local seat = heli:FindFirstChildWhichIsA("VehicleSeat", true)

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
align.Responsiveness = 8
align.Parent = seat

local groundY = seat.Position.Y
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
	local flying = seat.Occupant ~= nil
	local targetY = flying and groundY + CRUISE_HEIGHT or groundY
	local height = seat.Position.Y - groundY
	if not flying and height < 2 then
		mover.MaxForce = 0 -- landed: let it rest
		align.MaxTorque = 0
		return
	end
	mover.MaxForce = 1e6
	align.MaxTorque = 1e6
	heading -= seat.SteerFloat * TURN_SPEED * deltaTime
	local yaw = CFrame.Angles(0, heading, 0)
	-- Tilt forward a little when flying forward, like a real helicopter
	align.CFrame = yaw * CFrame.Angles(-seat.ThrottleFloat * 0.2, 0, 0)
	local climb = math.clamp((targetY - seat.Position.Y) * 0.8, -15, 15)
	local forward = flying and yaw.LookVector * seat.ThrottleFloat * SPEED or Vector3.zero
	mover.VectorVelocity = forward + Vector3.new(0, climb, 0)
end)
