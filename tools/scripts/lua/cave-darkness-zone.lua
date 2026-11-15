-- @title Dark cave zone
-- @category World and effects
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and make a Folder named DarkZones in Workspace with invisible, non-colliding Parts filling your caves.
-- @keywords cave darkness, dark area, spooky cave lighting, darker inside, lights dim in cave
-- @about The screen slowly gets darker and colder when you walk into a cave, and brightens again when you come out.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local DARK_BRIGHTNESS = -0.35
local DARK_TINT = Color3.fromRGB(190, 200, 255)

local player = Players.LocalPlayer
local zones = workspace:WaitForChild("DarkZones")

local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "CaveDarkness"
grade.Parent = Lighting

local function isInside(part, point)
	local p = part.CFrame:PointToObjectSpace(point)
	local half = part.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z
end

local dark = false
while true do
	task.wait(0.25)
	local camera = workspace.CurrentCamera
	local inside = false
	for _, zone in ipairs(zones:GetChildren()) do
		if zone:IsA("BasePart") and isInside(zone, camera.CFrame.Position) then
			inside = true
			break
		end
	end
	if inside ~= dark then
		dark = inside
		local goal = dark and { Brightness = DARK_BRIGHTNESS, TintColor = DARK_TINT, Saturation = -0.4 }
			or { Brightness = 0, TintColor = Color3.new(1, 1, 1), Saturation = 0 }
		TweenService:Create(grade, TweenInfo.new(1.5), goal):Play()
	end
end
