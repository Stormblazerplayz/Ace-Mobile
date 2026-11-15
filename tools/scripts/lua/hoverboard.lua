-- @title Hoverboard
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a VehicleSeat shaped like a flat board (make it about 2 x 0.5 x 5 studs and unanchored).
-- @keywords hoverboard, hover board, floating board, skateboard, hover vehicle
-- @about Stand on the board to ride it: it floats above the ground and over bumps, W and S go forward and back, A and D turn.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these!
local HOVER_HEIGHT = 3
local SPEED = 45
local TURN_SPEED = 2.5

local board = script.Parent

local attachment = Instance.new("Attachment")
attachment.Parent = board
local mover = Instance.new("LinearVelocity")
mover.Attachment0 = attachment
mover.RelativeTo = Enum.ActuatorRelativeTo.World
mover.MaxForce = 0
mover.Parent = board
local align = Instance.new("AlignOrientation")
align.Mode = Enum.OrientationAlignmentMode.OneAttachment
align.Attachment0 = attachment
align.MaxTorque = 0
align.Responsiveness = 20
align.Parent = board

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local heading = select(2, board.CFrame:ToEulerAnglesYXZ())

board:GetPropertyChangedSignal("Occupant"):Connect(function()
	local humanoid = board.Occupant
	local player = humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
	if player then
		pcall(board.SetNetworkOwner, board, player)
	else
		pcall(board.SetNetworkOwnershipAuto, board)
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	local rider = board.Occupant
	if not rider then
		mover.MaxForce = 0
		align.MaxTorque = 0
		return
	end
	mover.MaxForce = 1e5
	align.MaxTorque = 1e5
	params.FilterDescendantsInstances = { board, rider.Parent }
	-- Look straight down to find the ground under the board
	local ground = workspace:Raycast(board.Position, Vector3.new(0, -20, 0), params)
	local up = 0
	if ground then
		up = (ground.Position.Y + HOVER_HEIGHT - board.Position.Y) * 6 -- spring up or down to the right height
	else
		up = -30 -- nothing below: fall
	end
	heading -= board.SteerFloat * TURN_SPEED * deltaTime
	local facing = CFrame.Angles(0, heading, 0)
	align.CFrame = facing
	mover.VectorVelocity = facing.LookVector * board.ThrottleFloat * SPEED + Vector3.new(0, up, 0)
end)
