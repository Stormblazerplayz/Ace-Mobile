-- @title Swinging pendulum blade
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored Part (the blade) that hangs below the spot it should swing from.
-- @keywords swinging blade, pendulum trap, swinging axe, swing back and forth trap, pendulum obstacle
-- @about Swings the part back and forth like a pendulum and hurts players it hits.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local ROPE_LENGTH = 12 -- studs from the blade up to the swing point
local MAX_ANGLE = 60 -- how far it swings to each side (degrees)
local SPEED = 1.5 -- bigger = faster swings
local DAMAGE = 100 -- 100 = instant reset
local HIT_COOLDOWN = 1 -- seconds before the same player can be hit again

local blade = script.Parent
blade.Anchored = true

-- The swing point is straight above where the blade starts
local pivot = blade.CFrame * CFrame.new(0, ROPE_LENGTH, 0)
local startTime = os.clock()

-- Every frame, work out the new angle with math.sin (it goes smoothly from -1 to 1)
RunService.Heartbeat:Connect(function()
	local t = os.clock() - startTime
	local angle = math.rad(MAX_ANGLE) * math.sin(t * SPEED)
	blade.CFrame = pivot * CFrame.Angles(0, 0, angle) * CFrame.new(0, -ROPE_LENGTH, 0)
end)

-- Hurt players that get hit
local lastHit = {}
blade.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not player or not humanoid then
		return
	end
	local now = os.clock()
	if now - (lastHit[player] or 0) < HIT_COOLDOWN then
		return
	end
	lastHit[player] = now
	humanoid:TakeDamage(DAMAGE)
end)

Players.PlayerRemoving:Connect(function(player)
	lastHit[player] = nil
end)
