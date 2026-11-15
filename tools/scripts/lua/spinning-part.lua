-- @title Spinning part
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside the Part you want to spin (it will be Anchored for you).
-- @keywords spinning part, spinner, rotating part, spinning bar, part that spins around
-- @about Spins the part around and around, and pushes players it hits.

local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local SPEED = 90 -- degrees per second (bigger = faster, negative = other way)
local AXIS = Vector3.new(0, 1, 0) -- spin around: (0,1,0) = flat like a fan, (1,0,0) = like a wheel

local part = script.Parent
part.Anchored = true

RunService.Heartbeat:Connect(function(dt)
	-- Turn a tiny bit every frame
	part.CFrame = part.CFrame * CFrame.fromAxisAngle(AXIS, math.rad(SPEED) * dt)
	-- Tell physics it's spinning, so it pushes players instead of sliding under them
	part.AssemblyAngularVelocity = part.CFrame:VectorToWorldSpace(AXIS) * math.rad(SPEED)
end)
