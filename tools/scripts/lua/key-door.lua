-- @title Key door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the door Part, and make a Tool named Key (with a Handle part) that players can get.
-- @keywords key door, locked door, door needs a key, unlock door with key, key card door
-- @about The door only opens for players who have the Key tool.

local Players = game:GetService("Players")

-- Settings: change these!
local KEY_NAME = "Key" -- the exact name of your key Tool
local OPEN_TIME = 3 -- seconds the door stays open
local USE_UP_KEY = false -- true = the key disappears after opening the door

local door = script.Parent
local closedTransparency = door.Transparency
local isOpen = false

-- Find the player who touched the door (even if it was their tool or hat)
local function getPlayer(hit)
	local model = hit.Parent
	local player = model and Players:GetPlayerFromCharacter(model)
	if not player and model and model.Parent then
		player = Players:GetPlayerFromCharacter(model.Parent)
	end
	return player
end

-- Look for the key in their hand or their backpack
local function findKey(player)
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	return (character and character:FindFirstChild(KEY_NAME))
		or (backpack and backpack:FindFirstChild(KEY_NAME))
end

door.Touched:Connect(function(hit)
	if isOpen then
		return
	end
	local player = getPlayer(hit)
	local key = player and findKey(player)
	if not key then
		return -- no key, no entry!
	end

	isOpen = true
	if USE_UP_KEY then
		key:Destroy()
	end
	door.CanCollide = false
	door.Transparency = 0.7

	task.wait(OPEN_TIME)
	door.CanCollide = true
	door.Transparency = closedTransparency
	isOpen = false
end)
