-- @title Enemy that guards its area
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an enemy NPC Model with a Humanoid and HumanoidRootPart.
-- @keywords aggro range, enemy leash, guard area enemy, attack range, mob ai
-- @about The enemy waits at home, attacks players who come close, and walks back home (healing up) if they run too far away.

local Players = game:GetService("Players")

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")

-- Settings: change these!
local AGGRO_RANGE = 30 -- notices players this close
local LEASH_RANGE = 60 -- gives up if it gets this far from home
local ATTACK_RANGE = 5
local DAMAGE = 15
local ATTACK_COOLDOWN = 1.2

root:SetNetworkOwner(nil)
local home = root.Position
local target = nil
local lastAttack = 0

local function closestPlayer()
	local best, bestDistance = nil, AGGRO_RANGE
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local theirRoot = character and character:FindFirstChild("HumanoidRootPart")
		local theirHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if theirRoot and theirHumanoid and theirHumanoid.Health > 0 then
			local distance = (theirRoot.Position - root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = character, distance
			end
		end
	end
	return best
end

while humanoid.Health > 0 do
	task.wait(0.2)
	local farFromHome = (root.Position - home).Magnitude > LEASH_RANGE
	local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
	if farFromHome or not targetHumanoid or targetHumanoid.Health <= 0 then
		target = nil
	end
	if not target and not farFromHome then
		target = closestPlayer()
	end

	if target then
		local theirRoot = target:FindFirstChild("HumanoidRootPart")
		if theirRoot then
			humanoid:MoveTo(theirRoot.Position)
			if (theirRoot.Position - root.Position).Magnitude <= ATTACK_RANGE and os.clock() - lastAttack > ATTACK_COOLDOWN then
				lastAttack = os.clock()
				target:FindFirstChildOfClass("Humanoid"):TakeDamage(DAMAGE)
			end
		end
	else
		-- Go home and heal back up
		humanoid:MoveTo(home)
		if (root.Position - home).Magnitude < 4 then
			humanoid.Health = humanoid.MaxHealth
		end
	end
end
