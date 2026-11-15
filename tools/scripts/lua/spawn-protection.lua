-- @title Spawn protection bubble
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords spawn protection, spawn shield, forcefield on spawn, safe after respawn, spawn kill protection
-- @about Gives a force field when you spawn that lasts a few seconds or until you walk away from spawn.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local PROTECT_SECONDS = 8
local LEAVE_DISTANCE = 30 -- walking this far from where you spawned ends it early

local function onCharacterAdded(character)
	local root = character:WaitForChild("HumanoidRootPart")
	task.wait() -- let the character get placed on its spawn first
	local spawnPosition = root.Position

	local shield = Instance.new("ForceField")
	shield.Visible = true
	shield.Parent = character -- a ForceField stops all damage from TakeDamage

	local endTime = os.clock() + PROTECT_SECONDS
	while shield.Parent and os.clock() < endTime do
		if (root.Position - spawnPosition).Magnitude > LEAVE_DISTANCE then
			break
		end
		task.wait(0.25)
	end
	shield:Destroy()
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)
