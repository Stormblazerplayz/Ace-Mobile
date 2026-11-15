-- @title Laser that turns on and off
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside a thin Anchored Part that is your laser beam (Neon material looks best).
-- @keywords laser trap, laser beam, blinking laser, laser that turns on and off, timed laser
-- @about The laser blinks on and off, and touching it while it is on resets you.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local ON_TIME = 2 -- seconds the laser is dangerous
local OFF_TIME = 2 -- seconds the laser is safe
local LASER_COLOR = Color3.fromRGB(255, 40, 40)

local laser = script.Parent
laser.Anchored = true
laser.CanCollide = false -- you walk through it (and get zapped!)
laser.Material = Enum.Material.Neon
laser.Color = LASER_COLOR

-- Touching the laser only works while CanTouch is true (when it is on)
laser.Touched:Connect(function(hit)
	local character = hit.Parent
	if not Players:GetPlayerFromCharacter(character) then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end)

-- Blink forever
while true do
	-- ON: you can see it and it hurts
	laser.Transparency = 0.2
	laser.CanTouch = true
	task.wait(ON_TIME)

	-- OFF: invisible and safe
	laser.Transparency = 1
	laser.CanTouch = false
	task.wait(OFF_TIME)
end
