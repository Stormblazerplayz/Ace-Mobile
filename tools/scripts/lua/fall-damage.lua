-- @title Fall damage
-- @category Players
-- @kind Script
-- @where Put this Script in StarterPlayer > StarterCharacterScripts.
-- @keywords fall damage, hurt when you fall, landing damage, high fall hurts, falling hurts
-- @about Players get hurt when they land after falling really fast; the faster they fell, the more it hurts.

local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local SAFE_SPEED = 60 -- falling slower than this never hurts
local DAMAGE_PER_SPEED = 1.2 -- damage for every unit of speed over the safe speed

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local fastestFall = 0

local connection
connection = RunService.Heartbeat:Connect(function()
	if humanoid.Health <= 0 or not root.Parent then
		connection:Disconnect()
		return
	end
	local downSpeed = -root.AssemblyLinearVelocity.Y
	if downSpeed > 10 then
		-- Falling: remember the fastest we fell
		fastestFall = math.max(fastestFall, downSpeed)
	elseif downSpeed < 3 and fastestFall > 0 then
		-- We suddenly stopped falling, so we just landed!
		if fastestFall > SAFE_SPEED then
			humanoid:TakeDamage((fastestFall - SAFE_SPEED) * DAMAGE_PER_SPEED)
		end
		fastestFall = 0
	end
end)
