-- @title Bouncy wall
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored wall Part.
-- @keywords bouncy wall, wall that bounces you back, rubber wall, knockback wall, boing wall
-- @about Players who touch the wall get bounced away from it with a springy boing.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local PUSH = 70 -- how hard you get pushed away
local UP = 30 -- a little upward bounce
local COOLDOWN = 0.5

local wall = script.Parent
local recent = {}

wall.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or recent[player] then
		return
	end
	recent[player] = true

	-- Direction from the wall toward the player (flat, no up or down)
	local away = root.Position - wall.Position
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 0.1 then
		away = wall.CFrame.LookVector
	end
	root.AssemblyLinearVelocity = away.Unit * PUSH + Vector3.new(0, UP, 0)

	-- Squish the wall a tiny bit for fun
	local size = wall.Size
	wall.Size = size * 0.95
	task.delay(0.1, function()
		wall.Size = size
	end)

	task.delay(COOLDOWN, function()
		recent[player] = nil
	end)
end)
