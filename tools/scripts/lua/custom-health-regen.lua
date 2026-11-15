-- @title Custom health regen
-- @category Players
-- @kind Script
-- @where Name this Script exactly Health and put it in StarterPlayer > StarterCharacterScripts (it replaces the Roblox one).
-- @keywords health regen, heal over time, regenerate health, faster healing, health regeneration
-- @about Heals players a little every second, but only after they have not been hurt for a few seconds.

-- Settings: change these numbers!
local HEAL_PER_SECOND = 3 -- health back each second
local WAIT_AFTER_HIT = 4 -- seconds after getting hurt before healing starts

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local lastHealth = humanoid.Health
local lastHurt = 0

-- Remember when we last lost health
humanoid.HealthChanged:Connect(function(health)
	if health < lastHealth then
		lastHurt = os.clock()
	end
	lastHealth = health
end)

while humanoid.Health > 0 do
	task.wait(1)
	if os.clock() - lastHurt >= WAIT_AFTER_HIT and humanoid.Health < humanoid.MaxHealth and humanoid.Health > 0 then
		humanoid.Health = math.min(humanoid.Health + HEAL_PER_SECOND, humanoid.MaxHealth)
		lastHealth = humanoid.Health
	end
end
