-- @title Sound on touch
-- @category World and effects
-- @kind Script
-- @where Put this Script inside a Part, and put a Sound inside the same Part (pick one from the Toolbox or paste a sound ID into its SoundId).
-- @keywords sound on touch, play a sound when touched, noise when you step on it, touch sound, sound effect part
-- @about Plays the part's sound when a player touches it.

local Players = game:GetService("Players")

-- Settings: change this number!
local COOLDOWN = 1 -- seconds before the same player can play it again

local part = script.Parent
local sound = part:FindFirstChildOfClass("Sound")
local lastPlayed = {}

if not sound then
	warn("Put a Sound inside " .. part.Name .. " so it has something to play!")
	return
end

part.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end

	-- Wait a bit between plays so it doesn't spam
	local now = os.clock()
	if lastPlayed[player] and now - lastPlayed[player] < COOLDOWN then
		return
	end
	lastPlayed[player] = now

	sound:Play()
end)

Players.PlayerRemoving:Connect(function(player)
	lastPlayed[player] = nil
end)
