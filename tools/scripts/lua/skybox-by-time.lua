-- @title Day and night skyboxes
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService and put two Sky objects named DaySky and NightSky in ServerStorage.
-- @keywords skybox change, night sky, day sky, swap skybox, starry night skybox
-- @about Swaps the skybox to your night sky after sunset and back to your day sky in the morning.

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

-- Settings: change these! (hours, 0 to 24)
local NIGHT_STARTS = 18.5
local DAY_STARTS = 6

local daySky = ServerStorage:WaitForChild("DaySky")
local nightSky = ServerStorage:WaitForChild("NightSky")
local current = nil

local function update()
	local hour = Lighting.ClockTime
	local wanted = (hour >= NIGHT_STARTS or hour < DAY_STARTS) and nightSky or daySky
	if wanted == current then
		return
	end
	current = wanted
	-- Remove any sky that is in Lighting now, then put a copy of the right one in
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end
	wanted:Clone().Parent = Lighting
end

Lighting:GetPropertyChangedSignal("ClockTime"):Connect(update)
update()
