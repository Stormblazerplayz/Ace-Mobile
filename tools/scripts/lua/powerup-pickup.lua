-- @title Speed power-up pickup
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside an Anchored, non-colliding Part (the power-up).
-- @keywords power up, powerup pickup, temporary boost, speed powerup, super jump powerup
-- @about Grabbing the power-up gives a speed and jump boost for a few seconds, then it respawns.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local SPEED_BOOST = 16 -- added to walk speed
local JUMP_BOOST = 10 -- added to jump height
local BOOST_TIME = 8
local RESPAWN_TIME = 15

local powerup = script.Parent
powerup.CanCollide = false
local available = true

powerup.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not available or not player or not humanoid or character:GetAttribute("Boosted") then
		return
	end
	available = false
	powerup.Transparency = 1

	-- Boost!
	character:SetAttribute("Boosted", true)
	humanoid.WalkSpeed += SPEED_BOOST
	humanoid.JumpHeight += JUMP_BOOST
	task.delay(BOOST_TIME, function()
		if humanoid.Parent then
			humanoid.WalkSpeed -= SPEED_BOOST
			humanoid.JumpHeight -= JUMP_BOOST
			character:SetAttribute("Boosted", nil)
		end
	end)

	task.wait(RESPAWN_TIME)
	powerup.Transparency = 0
	available = true
end)
