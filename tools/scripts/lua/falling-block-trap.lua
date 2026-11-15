-- @title Falling block trap
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored Part that players walk on.
-- @keywords falling block, block falls when stepped on, drop away floor, collapsing block, falling floor trap
-- @about When a player steps on the block it shakes, falls down, then comes back a few seconds later.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local SHAKE_TIME = 0.6 -- seconds of shaking before it drops
local COME_BACK_TIME = 4 -- seconds before it comes back

local block = script.Parent
local homeCFrame = block.CFrame -- remember where it started
local busy = false

block.Touched:Connect(function(hit)
	if busy or not Players:GetPlayerFromCharacter(hit.Parent) then
		return
	end
	busy = true

	-- Shake a little so players know it is going to fall
	local shakeEnd = os.clock() + SHAKE_TIME
	while os.clock() < shakeEnd do
		local wiggle = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)) / 100
		block.CFrame = homeCFrame + wiggle
		task.wait(0.05)
	end

	-- Drop it! (unanchored parts fall because of gravity)
	block.CFrame = homeCFrame
	block.Anchored = false
	block.CanCollide = false
	task.wait(COME_BACK_TIME)

	-- Put it back home
	block.Anchored = true
	block.AssemblyLinearVelocity = Vector3.zero
	block.AssemblyAngularVelocity = Vector3.zero
	block.CFrame = homeCFrame
	block.CanCollide = true
	busy = false
end)
