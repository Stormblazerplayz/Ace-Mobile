-- @title Street lights that turn on at night
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService and make a Folder named StreetLights in Workspace with your lamp Parts (each with a PointLight or SpotLight inside).
-- @keywords street lights, lights on at night, lamp posts, night lights, automatic lamps
-- @about Turns every lamp on when it gets dark and off in the morning, using the time of day in Lighting.

local Lighting = game:GetService("Lighting")

-- Settings: change these! (hours, 0 to 24)
local LIGHTS_ON_AT = 18
local LIGHTS_OFF_AT = 6.5

local folder = workspace:WaitForChild("StreetLights")
local lightsOn = nil

local function setLights(on)
	for _, thing in ipairs(folder:GetDescendants()) do
		if thing:IsA("Light") then
			thing.Enabled = on
		elseif thing:IsA("BasePart") and thing:GetAttribute("Bulb") ~= false then
			-- Bulbs glow at night (give a part the attribute Bulb = false to skip it)
			thing.Material = on and Enum.Material.Neon or Enum.Material.Glass
		end
	end
end

local function update()
	local hour = Lighting.ClockTime
	local shouldBeOn = hour >= LIGHTS_ON_AT or hour < LIGHTS_OFF_AT
	if shouldBeOn ~= lightsOn then
		lightsOn = shouldBeOn
		setLights(lightsOn)
	end
end

Lighting:GetPropertyChangedSignal("ClockTime"):Connect(update)
update()
