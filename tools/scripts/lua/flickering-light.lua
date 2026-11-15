-- @title Flickering light
-- @category World and effects
-- @kind Script
-- @where Put this Script inside a lamp Part that has a PointLight, SpotLight or SurfaceLight inside it.
-- @keywords flickering light, broken light, spooky lamp, light flickers, horror light
-- @about Makes the light flicker on and off at random like a broken bulb in a horror game.

-- Settings: change these numbers!
local FLICKER_CHANCE = 0.3 -- how often it flickers (0 to 1)
local MIN_BRIGHTNESS = 0

local lamp = script.Parent
local light = lamp:FindFirstChildWhichIsA("Light")
if not light then
	warn("Put a PointLight, SpotLight or SurfaceLight inside the lamp!")
	return
end
local normalBrightness = light.Brightness
local normalMaterial = lamp.Material

local function setOn(on)
	light.Brightness = on and normalBrightness or MIN_BRIGHTNESS
	lamp.Material = on and normalMaterial or Enum.Material.SmoothPlastic
end

while true do
	if math.random() < FLICKER_CHANCE then
		-- A quick burst of flickers
		for _ = 1, math.random(2, 6) do
			setOn(false)
			task.wait(math.random() * 0.1 + 0.03)
			setOn(true)
			task.wait(math.random() * 0.15 + 0.03)
		end
	end
	task.wait(math.random() * 2 + 0.5)
end
