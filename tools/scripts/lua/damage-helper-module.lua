-- @title Damage helper with kill credit (module)
-- @category Tools and combat
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it Damage, then require it from your server weapon Scripts.
-- @keywords damage module, creator tag, kill credit, team damage check, who killed who
-- @about One safe function for hurting things: it skips teammates, respects force fields and leaves a creator tag so kill rewards know who did it.

--[[ How to use it from a server Script:
	local Damage = require(game.ServerScriptService.Damage)
	Damage.deal(attackerPlayer, enemyHumanoid, 25)
	if Damage.canHurt(attackerPlayer, enemyHumanoid) then ... end
]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local TAG_TIME = 3 -- seconds a hit still counts for the kill

local Damage = {}

-- Is this humanoid allowed to be hurt by this player?
function Damage.canHurt(attacker, humanoid)
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local victim = Players:GetPlayerFromCharacter(humanoid.Parent)
	if victim == attacker then
		return false -- no hurting yourself
	end
	if victim and attacker and not attacker.Neutral and victim.Team ~= nil and victim.Team == attacker.Team then
		return false -- same team
	end
	return true
end

-- Hurt a humanoid and remember who did it. Returns true if damage was dealt.
function Damage.deal(attacker, humanoid, amount)
	if not Damage.canHurt(attacker, humanoid) then
		return false
	end
	-- Swap the old tag for a fresh one
	local old = humanoid:FindFirstChild("creator")
	if old then
		old:Destroy()
	end
	if attacker then
		local tag = Instance.new("ObjectValue")
		tag.Name = "creator"
		tag.Value = attacker
		tag.Parent = humanoid
		Debris:AddItem(tag, TAG_TIME)
	end
	humanoid:TakeDamage(amount) -- TakeDamage does nothing if they have a ForceField
	return true
end

-- Who last hurt this humanoid? (a Player, or nil)
function Damage.getKiller(humanoid)
	local tag = humanoid:FindFirstChild("creator")
	return tag and tag.Value
end

return Damage
