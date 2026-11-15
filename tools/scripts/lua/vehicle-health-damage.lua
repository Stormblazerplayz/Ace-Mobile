-- @title Car crash damage
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a car Model with a VehicleSeat.
-- @keywords vehicle health, crash damage, car breaks, smoking engine, car explodes
-- @about Hard crashes hurt the car; it starts smoking when badly damaged and explodes when its health reaches zero.

-- Settings: change these!
local MAX_HEALTH = 100
local CRASH_SPEED = 30 -- losing more speed than this in one moment counts as a crash
local RESPAWN_PARTS_AFTER = 10

local car = script.Parent
local seat = car:FindFirstChildWhichIsA("VehicleSeat", true)
car:SetAttribute("Health", MAX_HEALTH)

local smoke = Instance.new("Smoke")
smoke.Enabled = false
smoke.Color = Color3.fromRGB(60, 60, 60)
smoke.Parent = seat

local lastVelocity = seat.AssemblyLinearVelocity
local destroyed = false

local function explode()
	destroyed = true
	local blast = Instance.new("Explosion")
	blast.Position = seat.Position
	blast.BlastRadius = 10
	blast.DestroyJointRadiusPercent = 0 -- do not kill players inside, just push them
	blast.Parent = workspace
	if seat.Occupant then
		seat.Occupant.Sit = false
	end
	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Color = Color3.fromRGB(30, 30, 30)
		end
	end
	seat.Disabled = true -- nobody can drive a wreck
	task.wait(RESPAWN_PARTS_AFTER)
	car:Destroy()
end

while car.Parent and not destroyed do
	task.wait(0.1)
	local velocity = seat.AssemblyLinearVelocity
	local speedLost = (lastVelocity - velocity).Magnitude
	lastVelocity = velocity
	if speedLost > CRASH_SPEED then
		local health = car:GetAttribute("Health") - (speedLost - CRASH_SPEED)
		car:SetAttribute("Health", math.max(0, health))
		smoke.Enabled = health < MAX_HEALTH * 0.4
		if health <= 0 then
			explode()
		end
	end
end
