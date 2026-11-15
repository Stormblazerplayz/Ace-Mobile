-- @title Train that follows a track
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a train Model (unanchored parts welded together, with a PrimaryPart set). Put Parts named 1, 2, 3... along the track in a Folder named TrainStops in Workspace.
-- @keywords train, railway, subway, tram ride, train stations
-- @about The train glides from stop to stop along the track, waits at each station so players can hop on, and players can ride on it.

local RunService = game:GetService("RunService")

-- Settings: change these!
local SPEED = 30 -- studs per second
local WAIT_AT_STOP = 5

local train = script.Parent
local main = train.PrimaryPart
local stopsFolder = workspace:WaitForChild("TrainStops")

local stops = {}
for _, part in ipairs(stopsFolder:GetChildren()) do
	if tonumber(part.Name) then
		table.insert(stops, part)
	end
end
table.sort(stops, function(a, b)
	return tonumber(a.Name) < tonumber(b.Name)
end)

-- Physics movers so players standing on the train ride along with it
main:SetNetworkOwner(nil)
local attachment = Instance.new("Attachment")
attachment.Parent = main
local alignPosition = Instance.new("AlignPosition")
alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
alignPosition.Attachment0 = attachment
alignPosition.MaxForce = 1e7
alignPosition.MaxVelocity = SPEED
alignPosition.Responsiveness = 20
alignPosition.Parent = main
local alignOrientation = Instance.new("AlignOrientation")
alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
alignOrientation.Attachment0 = attachment
alignOrientation.MaxTorque = 1e7
alignOrientation.Responsiveness = 10
alignOrientation.Parent = main

local height = 3 -- how far above each stop part the train rides
local index = 1
alignPosition.Position = main.Position
alignOrientation.CFrame = main.CFrame

while #stops > 1 do
	local stop = stops[index]
	local target = stop.Position + Vector3.new(0, height, 0)
	-- Face the next stop
	local flat = (target - main.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude > 1 then
		alignOrientation.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit)
	end
	alignPosition.Position = target
	-- Wait until we are close to the stop
	while (main.Position - target).Magnitude > 2 do
		RunService.Heartbeat:Wait()
	end
	task.wait(WAIT_AT_STOP)
	index = index % #stops + 1
end
