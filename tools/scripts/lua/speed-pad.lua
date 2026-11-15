-- @title Speed pad
-- @category Players
-- @kind Script
-- @where Put this Script inside the Part you want to be a speed pad.
-- @keywords speed pad, speed boost, run faster part, boost pad, go fast pad
-- @about Makes players super fast for a few seconds, then back to normal speed.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local BOOST_SPEED = 50 -- speed while boosted
local NORMAL_SPEED = 16 -- normal Roblox speed is 16
local BOOST_TIME = 3 -- seconds the boost lasts

local pad = script.Parent
local boosted = {} -- players who are boosted right now

pad.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player or boosted[player] then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Zoom!
	boosted[player] = true
	humanoid.WalkSpeed = BOOST_SPEED

	-- After a few seconds, go back to normal
	task.delay(BOOST_TIME, function()
		if humanoid.Parent then
			humanoid.WalkSpeed = NORMAL_SPEED
		end
		boosted[player] = nil
	end)
end)
