-- @title Healing pad
-- @category Players
-- @kind Script
-- @where Put this Script inside the Part you want to heal players.
-- @keywords healing pad, heal part, health pad, get health back, medkit pad
-- @about Gives players health back when they touch it, with a wait before it works again.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local HEAL_AMOUNT = 25 -- health given each time
local COOLDOWN = 5 -- seconds before the same player can heal again

local pad = script.Parent
local lastHeal = {} -- when each player last healed

pad.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	-- Skip if they're gone, or already at full health
	if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
		return
	end

	-- Still cooling down? Not yet!
	local now = os.clock()
	if lastHeal[player] and now - lastHeal[player] < COOLDOWN then
		return
	end
	lastHeal[player] = now

	-- Heal, but never above max health
	humanoid.Health = math.min(humanoid.Health + HEAL_AMOUNT, humanoid.MaxHealth)
end)

Players.PlayerRemoving:Connect(function(player)
	lastHeal[player] = nil
end)
