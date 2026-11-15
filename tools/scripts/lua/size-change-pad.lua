-- @title Shrink and grow pad
-- @category Players
-- @kind Script
-- @where Put this Script inside an Anchored Part that players step on.
-- @keywords shrink pad, grow pad, make player bigger, make player tiny, change size, giant mode
-- @about Stepping on the pad scales your whole character to a new size (tiny or giant).

local Players = game:GetService("Players")

-- Settings: change these numbers!
local NEW_SCALE = 0.5 -- 0.5 = half size, 2 = double size, 1 = normal
local COOLDOWN = 2

local pad = script.Parent
local recent = {}

pad.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not player or not humanoid or humanoid.Health <= 0 or recent[player] then
		return
	end
	recent[player] = true

	-- ScaleTo resizes the whole model, body, hats and all
	if character:GetScale() ~= NEW_SCALE then
		character:ScaleTo(NEW_SCALE)
	end

	task.delay(COOLDOWN, function()
		recent[player] = nil
	end)
end)
