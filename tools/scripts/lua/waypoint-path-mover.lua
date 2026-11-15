-- @title Move along a path of waypoints
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an Anchored Part, then make a Folder named Waypoints next to it with Parts named 1, 2, 3 and so on.
-- @keywords waypoints, follow a path, move between points, patrol path part, part travels a route
-- @about Moves the part smoothly from waypoint 1 to 2 to 3 and back to the start, at the same speed the whole way.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local SPEED = 12 -- studs per second
local PAUSE = 0.5 -- seconds to wait at each waypoint
local FACE_DIRECTION = true -- turn to face where it is going?

local part = script.Parent
part.Anchored = true
local folder = part.Parent:WaitForChild("Waypoints")

-- Put the waypoints in number order
local points = {}
for _, p in ipairs(folder:GetChildren()) do
	if p:IsA("BasePart") and tonumber(p.Name) then
		table.insert(points, p)
		p.Transparency = 1
		p.CanCollide = false
	end
end
table.sort(points, function(a, b)
	return tonumber(a.Name) < tonumber(b.Name)
end)
if #points < 2 then
	warn("Add at least 2 waypoints named 1 and 2")
	return
end

local index = 1
while true do
	local target = points[index]
	local distance = (target.Position - part.Position).Magnitude
	local goal = CFrame.new(target.Position) * part.CFrame.Rotation
	if FACE_DIRECTION and distance > 0.1 then
		goal = CFrame.lookAt(target.Position, target.Position + (target.Position - part.Position).Unit)
	end
	-- Time = distance / speed, so long gaps take longer and the speed stays the same
	local tween = TweenService:Create(part, TweenInfo.new(distance / SPEED, Enum.EasingStyle.Linear), { CFrame = goal })
	tween:Play()
	tween.Completed:Wait()
	task.wait(PAUSE)
	index = index % #points + 1
end
