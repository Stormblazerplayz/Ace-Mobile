-- @title Moving saw blade
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored Cylinder Part (the saw) standing on its edge.
-- @keywords saw blade, buzz saw, spinning saw trap, moving saw, sawblade obby
-- @about The saw spins fast and slides back and forth, resetting anyone it touches.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local SLIDE_DISTANCE = 16 -- how far it slides each way (studs)
local SLIDE_SPEED = 1 -- bigger = faster sliding
local SPIN_SPEED = 720 -- degrees per second

local saw = script.Parent
saw.Anchored = true
local start = saw.CFrame
local spin = 0

RunService.Heartbeat:Connect(function(deltaTime)
	spin = (spin + SPIN_SPEED * deltaTime) % 360
	-- Slide along the saw's front direction using a smooth sine wave
	local offset = math.sin(os.clock() * SLIDE_SPEED) * SLIDE_DISTANCE
	-- A Roblox cylinder spins around its X axis
	saw.CFrame = start * CFrame.new(0, 0, offset) * CFrame.Angles(math.rad(spin), 0, 0)
end)

saw.Touched:Connect(function(hit)
	local character = hit.Parent
	if Players:GetPlayerFromCharacter(character) then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
end)
