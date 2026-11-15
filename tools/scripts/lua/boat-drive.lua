-- @title Drivable boat
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a boat Model with a VehicleSeat. Make the boat parts light (Custom Physical Properties, low Density) so it floats on Terrain water.
-- @keywords boat, drive boat, water vehicle, speedboat, sail on water
-- @about Pushes the boat forward and turns it with W, A, S, D from the VehicleSeat, keeping it upright on the waves.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these!
local SPEED = 40
local TURN_SPEED = 1.2 -- radians per second

local boat = script.Parent
local seat = boat:FindFirstChildWhichIsA("VehicleSeat", true)

local attachment = Instance.new("Attachment")
attachment.Parent = seat

-- LinearVelocity pushes along the water (only X and Z, so it can still bob up and down)
local push = Instance.new("LinearVelocity")
push.Attachment0 = attachment
push.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
push.PrimaryTangentAxis = Vector3.new(1, 0, 0)
push.SecondaryTangentAxis = Vector3.new(0, 0, 1)
push.RelativeTo = Enum.ActuatorRelativeTo.World
push.MaxForce = 0
push.Parent = seat

-- AlignOrientation keeps it flat and facing where we steer
local align = Instance.new("AlignOrientation")
align.Mode = Enum.OrientationAlignmentMode.OneAttachment
align.Attachment0 = attachment
align.MaxTorque = 0
align.Responsiveness = 15
align.Parent = seat

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
		push.MaxForce = 0
		align.MaxTorque = 0
		return
	end
	push.MaxForce = 50000
	align.MaxTorque = 100000
	heading -= seat.SteerFloat * TURN_SPEED * deltaTime
	align.CFrame = CFrame.Angles(0, heading, 0)
	local forward = CFrame.Angles(0, heading, 0).LookVector
	push.PlaneVelocity = Vector2.new(forward.X, forward.Z) * seat.ThrottleFloat * SPEED
end)
