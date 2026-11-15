-- @title Car fuel and gas station
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a car Model with a VehicleSeat. To refuel, make an anchored Part named GasPump somewhere and drive into it.
-- @keywords fuel, gas tank, petrol, refuel station, out of gas
-- @about The car uses fuel while you drive; when it runs out the car stops, and touching a GasPump fills it back up.

-- Settings: change these!
local MAX_FUEL = 100
local USE_PER_SECOND = 1.5 -- at full throttle

local car = script.Parent
local seat = car:FindFirstChildWhichIsA("VehicleSeat", true)
local normalSpeed = seat.MaxSpeed
local normalTorque = seat.Torque
car:SetAttribute("Fuel", MAX_FUEL) -- a speed GUI can show this

-- Refill when any part of the car touches a GasPump
for _, part in ipairs(car:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			if hit.Name == "GasPump" and car:GetAttribute("Fuel") < MAX_FUEL then
				car:SetAttribute("Fuel", MAX_FUEL)
				local humanoid = seat.Occupant
				local player = humanoid and game:GetService("Players"):GetPlayerFromCharacter(humanoid.Parent)
				if player then
					player:SetAttribute("Notice", "Tank full!")
				end
			end
		end)
	end
end

while car.Parent do
	task.wait(0.5)
	local fuel = car:GetAttribute("Fuel")
	if seat.Occupant and fuel > 0 then
		fuel = math.max(0, fuel - math.abs(seat.ThrottleFloat) * USE_PER_SECOND * 0.5)
		car:SetAttribute("Fuel", fuel)
	end
	-- No fuel means no engine power (works with the built-in VehicleSeat motor)
	seat.MaxSpeed = fuel > 0 and normalSpeed or 0
	seat.Torque = fuel > 0 and normalTorque or 0
	car:SetAttribute("OutOfFuel", fuel <= 0) -- your own drive script can check this
end
