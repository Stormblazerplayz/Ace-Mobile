-- @title Jump pad
-- @category Players
-- @kind Script
-- @where Put this Script inside the Part you want to be a jump pad.
-- @keywords jump pad, launch pad, bounce pad, trampoline, super jump part, boost you up
-- @about Launches players high into the air when they step on it.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local JUMP_POWER = 100 -- how fast you shoot up (bigger = higher)
local COOLDOWN = 0.5 -- seconds before the same player can bounce again

local pad = script.Parent
local recent = {} -- players who just bounced

pad.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player or recent[player] then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	recent[player] = true
	-- Keep sideways speed, but shoot straight up!
	local velocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, JUMP_POWER, velocity.Z)

	task.delay(COOLDOWN, function()
		recent[player] = nil
	end)
end)
