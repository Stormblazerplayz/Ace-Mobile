-- @title Wind zone that pushes you
-- @category Obstacles
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts, then make a Folder named WindZones in Workspace with invisible, non-colliding Parts inside (the front face of each part points where the wind blows).
-- @keywords wind zone, wind pushes you, blowing wind, fan push, strong wind area
-- @about Players standing inside a wind zone get pushed the way the part is facing.

local RunService = game:GetService("RunService")

-- Settings: change this number! (each part can also have a number Attribute named Strength)
local DEFAULT_STRENGTH = 40 -- how hard the wind pushes

local character = script.Parent
local root = character:WaitForChild("HumanoidRootPart")
local windZones = workspace:WaitForChild("WindZones")

-- Is a point inside a (possibly rotated) part?
local function isInside(part, point)
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local half = part.Size / 2
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z
end

RunService.Heartbeat:Connect(function(deltaTime)
	for _, zone in ipairs(windZones:GetChildren()) do
		if zone:IsA("BasePart") and isInside(zone, root.Position) then
			local strength = zone:GetAttribute("Strength") or DEFAULT_STRENGTH
			-- Add a little speed every frame in the direction the zone faces
			root.AssemblyLinearVelocity += zone.CFrame.LookVector * strength * deltaTime
		end
	end
end)
