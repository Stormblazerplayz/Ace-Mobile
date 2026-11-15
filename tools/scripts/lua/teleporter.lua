-- @title Teleporter pair
-- @category Players
-- @kind Script
-- @where Put this Script inside a Model or Folder in Workspace that holds two parts named TeleportA and TeleportB.
-- @keywords teleporter, teleport, teleport pad, portal, teleport to another part, warp pad
-- @about Touching one pad sends you to the other pad, and back again.

local Players = game:GetService("Players")

-- Settings: change this number!
local COOLDOWN = 2 -- seconds before you can teleport again (stops bouncing back and forth)

local holder = script.Parent
local padA = holder:WaitForChild("TeleportA")
local padB = holder:WaitForChild("TeleportB")
local recent = {} -- players who just teleported

-- Touching fromPad sends you on top of toPad
local function linkPads(fromPad, toPad)
	fromPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player or recent[player] then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		recent[player] = true
		-- Land a little above the other pad
		local above = toPad.Position + Vector3.new(0, toPad.Size.Y / 2 + 3, 0)
		character:PivotTo(CFrame.new(above))

		task.delay(COOLDOWN, function()
			recent[player] = nil
		end)
	end)
end

linkPads(padA, padB)
linkPads(padB, padA)
