-- @title Rising lava
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside a big flat lava Part placed at the bottom of your map (make it Anchored).
-- @keywords rising lava, lava rises, floor is lava, flood rising, water rising, climb before the lava
-- @about The lava slowly rises up, kills anyone it touches, then drops back down and starts again.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local RISE_SPEED = 2 -- studs per second (bigger = faster)
local RISE_HEIGHT = 100 -- how many studs the lava climbs
local WAIT_AT_TOP = 5 -- seconds it stays at the top
local WAIT_AT_BOTTOM = 5 -- seconds before it rises again

local lava = script.Parent
lava.Anchored = true
local startCFrame = lava.CFrame

-- Touching the lava resets the player
lava.Touched:Connect(function(hit)
	local character = hit.Parent
	if not Players:GetPlayerFromCharacter(character) then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end)

while true do
	task.wait(WAIT_AT_BOTTOM)

	-- Rise a little bit every frame
	local risen = 0
	while risen < RISE_HEIGHT do
		local dt = RunService.Heartbeat:Wait()
		risen = math.min(risen + RISE_SPEED * dt, RISE_HEIGHT)
		lava.CFrame = startCFrame + Vector3.new(0, risen, 0)
	end

	task.wait(WAIT_AT_TOP)
	lava.CFrame = startCFrame -- back to the bottom
end
