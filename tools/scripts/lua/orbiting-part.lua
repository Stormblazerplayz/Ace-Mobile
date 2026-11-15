-- @title Part that orbits around another
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an Anchored Part, and set the CENTER_NAME below to the name of a part in Workspace it should circle around.
-- @keywords orbit, orbiting part, circle around, planet orbit, moon around planet, part goes in circles
-- @about Moves the part round and round in a circle around a center part, like a moon around a planet.

local RunService = game:GetService("RunService")

-- Settings: change these!
local CENTER_NAME = "Planet" -- the part in Workspace to circle around
local RADIUS = 20 -- how far away it orbits
local SECONDS_PER_LAP = 8
local FACE_CENTER = true -- keep facing the middle?

local part = script.Parent
part.Anchored = true
local center = workspace:WaitForChild(CENTER_NAME)
local height = part.Position.Y - center.Position.Y -- keep the height it started at

RunService.Heartbeat:Connect(function()
	local angle = (os.clock() / SECONDS_PER_LAP) * math.pi * 2
	-- cos and sin give a point on a circle
	local offset = Vector3.new(math.cos(angle) * RADIUS, height, math.sin(angle) * RADIUS)
	local position = center.Position + offset
	if FACE_CENTER then
		part.CFrame = CFrame.lookAt(position, center.Position)
	else
		part.CFrame = CFrame.new(position) * part.CFrame.Rotation
	end
end)
