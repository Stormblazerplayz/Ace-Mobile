-- @title Remove abandoned cars
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a car Model that has a VehicleSeat.
-- @keywords despawn car, abandoned vehicle, clean up cars, empty vehicle timer, remove unused car
-- @about If nobody sits in the car for a while, it fades away so the map does not fill up with old cars.

-- Settings: change this!
local EMPTY_TIME = 60 -- seconds with no driver before it is removed

local car = script.Parent
local seat = car:FindFirstChildWhichIsA("VehicleSeat", true)
local emptySince = os.clock()

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	if not seat.Occupant then
		emptySince = os.clock()
	end
end)

while car.Parent do
	task.wait(5)
	-- Also check passenger seats: any Seat with someone in it keeps the car
	local anyone = false
	for _, s in ipairs(car:GetDescendants()) do
		if (s:IsA("Seat") or s:IsA("VehicleSeat")) and s.Occupant then
			anyone = true
		end
	end
	if anyone then
		emptySince = os.clock()
	elseif os.clock() - emptySince > EMPTY_TIME then
		-- Fade out, then delete
		for step = 1, 10 do
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = math.max(part.Transparency, step / 10)
				end
			end
			task.wait(0.1)
		end
		car:Destroy()
	end
end
