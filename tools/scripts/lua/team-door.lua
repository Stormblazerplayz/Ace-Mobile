-- @title Team-only door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the door Part, make sure you have Teams (in the Teams service), and set TEAM_NAME below.
-- @keywords team door, team only door, vip room door, only my team can enter, team base door
-- @about Players on one team can walk right through the door, but everyone else is blocked.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

-- Settings: change this to your team's exact name!
local TEAM_NAME = "Red"

local door = script.Parent
local doorGroup = "TeamDoor_" .. TEAM_NAME
local memberGroup = "TeamMembers_" .. TEAM_NAME

-- Collision groups: team members and this door don't bump into each other
for _, groupName in ipairs({ doorGroup, memberGroup }) do
	if not PhysicsService:IsCollisionGroupRegistered(groupName) then
		PhysicsService:RegisterCollisionGroup(groupName)
	end
end
PhysicsService:CollisionGroupSetCollidable(doorGroup, memberGroup, false)
door.CollisionGroup = doorGroup

local function isOnTeam(player)
	return player.Team ~= nil and player.Team.Name == TEAM_NAME
end

-- Put a body part in the right group
local function updatePart(player, part)
	if not part:IsA("BasePart") then
		return
	end
	if isOnTeam(player) then
		part.CollisionGroup = memberGroup
	elseif part.CollisionGroup == memberGroup then
		part.CollisionGroup = "Default"
	end
end

local function updateCharacter(player, character)
	for _, part in ipairs(character:GetDescendants()) do
		updatePart(player, part)
	end
end

local function onPlayerAdded(player)
	local function onCharacter(character)
		updateCharacter(player, character)
		character.DescendantAdded:Connect(function(part)
			updatePart(player, part)
		end)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
	-- Switching teams? Update right away
	player:GetPropertyChangedSignal("Team"):Connect(function()
		if player.Character then
			updateCharacter(player, player.Character)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
