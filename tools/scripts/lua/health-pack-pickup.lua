-- @title Health pack pickup
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside an Anchored Part or the main Part of a medkit model.
-- @keywords health pack, medkit pickup, first aid kit, heal pickup, health item respawns
-- @about Touching the health pack heals you once, then it disappears and comes back later.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local HEAL_AMOUNT = 50
local RESPAWN_TIME = 15

local pack = script.Parent
local ready = true

pack.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not ready or not Players:GetPlayerFromCharacter(character) or not humanoid then
		return
	end
	-- Do not waste it on someone with full health
	if humanoid.Health >= humanoid.MaxHealth or humanoid.Health <= 0 then
		return
	end
	ready = false
	humanoid.Health = math.min(humanoid.Health + HEAL_AMOUNT, humanoid.MaxHealth)
	pack.Transparency = 1
	pack.CanTouch = false
	task.wait(RESPAWN_TIME)
	pack.Transparency = 0
	pack.CanTouch = true
	ready = true
end)
