-- @title Hitbox helper (module)
-- @category Tools and combat
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it Hitbox, then require it from your server weapon Scripts.
-- @keywords hitbox module, melee hitbox, find enemies in box, attack area, overlap params helper
-- @about Finds every enemy humanoid inside a box or a sphere (never the attacker), so making melee attacks is one line.

--[[ How to use it from a server Script:
	local Hitbox = require(game.ServerScriptService.Hitbox)
	-- A 5 by 5 by 6 box just in front of the player
	local enemies = Hitbox.box(character, root.CFrame * CFrame.new(0, 0, -4), Vector3.new(5, 5, 6))
	for _, humanoid in ipairs(enemies) do
		humanoid:TakeDamage(10)
	end
	-- Everyone within 12 studs of a spot
	local nearby = Hitbox.sphere(character, root.Position, 12)
]]

local Hitbox = {}

-- Turn a list of parts into a list of humanoids (each one only once)
local function humanoidsFrom(parts, ignoreCharacter)
	local found, list = {}, {}
	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and model ~= ignoreCharacter and humanoid.Health > 0 and not found[humanoid] then
			found[humanoid] = true
			table.insert(list, humanoid)
		end
	end
	return list
end

local function makeParams(ignoreCharacter)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreCharacter and { ignoreCharacter } or {}
	return params
end

function Hitbox.box(attackerCharacter, cframe, size)
	local parts = workspace:GetPartBoundsInBox(cframe, size, makeParams(attackerCharacter))
	return humanoidsFrom(parts, attackerCharacter)
end

function Hitbox.sphere(attackerCharacter, position, radius)
	local parts = workspace:GetPartBoundsInRadius(position, radius, makeParams(attackerCharacter))
	return humanoidsFrom(parts, attackerCharacter)
end

-- Optional: show the box for half a second while you test (only in Studio)
function Hitbox.debugBox(cframe, size)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 0.7
	part.Color = Color3.new(1, 0, 0)
	part.CFrame = cframe
	part.Size = size
	part.Parent = workspace
	game:GetService("Debris"):AddItem(part, 0.5)
end

return Hitbox
