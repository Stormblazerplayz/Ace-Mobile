-- @title Weather changer
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService (add the Rain, Snow and Thunderstorm scripts to see the weather).
-- @keywords weather changer, random weather, weather system, change the weather, sunny rainy snowy
-- @about Picks new random weather every few minutes (Clear, Rain, Storm or Snow) and tells everyone through a Workspace attribute.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- Settings: weather and how often each happens (bigger = more often)
local WEATHER = {
	{ name = "Clear", weight = 50, fogEnd = 100000 },
	{ name = "Rain", weight = 25, fogEnd = 600 },
	{ name = "Storm", weight = 10, fogEnd = 300 },
	{ name = "Snow", weight = 15, fogEnd = 400 },
}
local CHANGE_EVERY = 180 -- seconds

local function pick()
	local total = 0
	for _, w in ipairs(WEATHER) do
		total += w.weight
	end
	local roll = math.random() * total
	for _, w in ipairs(WEATHER) do
		roll -= w.weight
		if roll <= 0 then
			return w
		end
	end
	return WEATHER[1]
end

while true do
	local weather = pick()
	workspace:SetAttribute("Weather", weather.name) -- client scripts read this
	-- Fog closes in for bad weather (only works if Lighting has no Atmosphere object)
	TweenService:Create(Lighting, TweenInfo.new(10), { FogEnd = weather.fogEnd }):Play()
	task.wait(CHANGE_EVERY)
end
