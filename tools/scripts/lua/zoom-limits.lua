-- @title Zoom limits indoors and out
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Optional: put see-through, CanCollide-off Parts covering your rooms in a Folder named IndoorZones.
-- @keywords zoom limit, max zoom, camera distance, indoor camera, stop zooming out
-- @about Sets how far players can zoom out, and zooms the camera in closer automatically when they walk inside a building.

local Players = game:GetService("Players")

-- Settings: change these!
local OUTDOOR_MAX_ZOOM = 40
local INDOOR_MAX_ZOOM = 12
local MIN_ZOOM = 2

local player = Players.LocalPlayer
local zones = workspace:FindFirstChild("IndoorZones")

player.CameraMinZoomDistance = MIN_ZOOM
player.CameraMaxZoomDistance = OUTDOOR_MAX_ZOOM

local function isInside(part, position)
	local offset = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

if not zones then
	return -- no indoor zones: just keep the outdoor limit
end

local wasInside = false
while true do
	task.wait(0.3)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local inside = false
	if root then
		for _, zone in ipairs(zones:GetChildren()) do
			if zone:IsA("BasePart") and isInside(zone, root.Position) then
				inside = true
				break
			end
		end
	end
	if inside ~= wasInside then
		wasInside = inside
		player.CameraMaxZoomDistance = inside and INDOOR_MAX_ZOOM or OUTDOOR_MAX_ZOOM
	end
end
