-- @title Sunset and night colors
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService (works with any day and night cycle script).
-- @keywords sunset colors, color grading, warm sunset, blue night tint, golden hour
-- @about Tints the whole world warm orange at sunrise and sunset and cool blue at night, changing smoothly with the time of day.

local Lighting = game:GetService("Lighting")

-- Settings: colors for each part of the day
local DAY = Color3.fromRGB(255, 255, 255)
local SUNSET = Color3.fromRGB(255, 200, 150)
local NIGHT = Color3.fromRGB(170, 190, 255)

local grade = Lighting:FindFirstChild("TimeOfDayGrade") or Instance.new("ColorCorrectionEffect")
grade.Name = "TimeOfDayGrade"
grade.Parent = Lighting

-- How close is a time to a target hour? (1 = right on it, 0 = far away)
local function closeness(hour, target, width)
	local distance = math.abs(hour - target)
	return math.clamp(1 - distance / width, 0, 1)
end

local function update()
	local hour = Lighting.ClockTime
	local sunsetAmount = math.max(closeness(hour, 6, 1.5), closeness(hour, 18, 1.5))
	local nightAmount = (hour < 5 or hour > 19.5) and 1 or math.max(closeness(hour, 4.5, 1), closeness(hour, 20, 1))
	local color = DAY:Lerp(SUNSET, sunsetAmount):Lerp(NIGHT, nightAmount)
	grade.TintColor = color
	grade.Saturation = 0.1 * sunsetAmount - 0.15 * nightAmount
end

Lighting:GetPropertyChangedSignal("ClockTime"):Connect(update)
update()
