-- @title Players walk through each other
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords player collisions off, walk through players, no collide players, collision groups, ghost players
-- @about Uses collision groups so players pass through each other but still stand on the map.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local GROUP = "Players"

-- Make a collision group that does not collide with itself
PhysicsService:RegisterCollisionGroup(GROUP)
PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)

local function setGroup(part)
	if part:IsA("BasePart") then
		part.CollisionGroup = GROUP
	end
end

local function onCharacterAdded(character)
	for _, part in ipairs(character:GetDescendants()) do
		setGroup(part)
	end
	-- Hats and tools added later get the group too
	character.DescendantAdded:Connect(setGroup)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end)
