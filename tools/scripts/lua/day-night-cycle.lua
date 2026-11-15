-- @title Day and night cycle
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords day night cycle, day and night, sun goes down, time of day, make it night
-- @about Makes the sun move across the sky so day turns into night and back again.

local Lighting = game:GetService("Lighting")

-- Settings: change these numbers!
local DAY_LENGTH = 10 -- minutes for one full day and night
local START_TIME = 8 -- the hour the game starts at (0 = midnight, 12 = noon)
local UPDATE_EVERY = 0.1 -- seconds between updates

Lighting.ClockTime = START_TIME

-- How many in-game hours pass each real second
local hoursPerSecond = 24 / (DAY_LENGTH * 60)

while true do
	local dt = task.wait(UPDATE_EVERY)
	-- Move the clock forward (% 24 makes it go back to 0 after midnight)
	Lighting.ClockTime = (Lighting.ClockTime + hoursPerSecond * dt) % 24
end
