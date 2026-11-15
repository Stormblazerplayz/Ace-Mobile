-- @title Foggy zone
-- @category World and effects
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and make a Folder named FogZones in Workspace with invisible, non-colliding Parts covering foggy areas.
-- @keywords fog zone, foggy area, misty forest, thick fog, spooky fog, mist area
-- @about When you walk into a fog zone thick fog rolls in, and it clears up again when you leave.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local FOG_DENSITY = 0.6 -- for Atmosphere (0 to 1)
local FOG_END = 60 -- for old-style fog (studs you can see)

local player = Players.LocalPlayer
local zones = workspace:WaitForChild("FogZones")
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local normalDensity = atmosphere and atmosphere.Density
local normalFogEnd = Lighting.FogEnd

local function isInside(part, point)
	local p = part.CFrame:PointToObjectSpace(point)
	local half = part.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z
end

local foggy = false
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
	if inside ~= foggy then
		foggy = inside
		local info = TweenInfo.new(2)
		if atmosphere then
			TweenService:Create(atmosphere, info, { Density = foggy and FOG_DENSITY or normalDensity }):Play()
		else
			TweenService:Create(Lighting, info, { FogEnd = foggy and FOG_END or normalFogEnd }):Play()
		end
	end
end
