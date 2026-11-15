-- @title Flip the car back over
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a car Model that has a VehicleSeat.
-- @keywords flip car, car upside down, unflip vehicle, reset car, stuck car fix
-- @about If the car lands upside down or on its side for 3 seconds, it lifts up and turns itself right-side up.

-- Settings: change this!
local STUCK_TIME = 3

local car = script.Parent
local seat = car:FindFirstChildWhichIsA("VehicleSeat", true)
local tippedSince = nil

while car.Parent do
	task.wait(0.5)
	-- UpVector.Y is 1 when the car is flat, 0 on its side, -1 upside down
	local up = seat.CFrame.UpVector.Y
	local slow = seat.AssemblyLinearVelocity.Magnitude < 5
	if up < 0.4 and slow then
		tippedSince = tippedSince or os.clock()
		if os.clock() - tippedSince > STUCK_TIME then
			-- Keep the direction it was facing, but make it flat and lift it up
			local look = seat.CFrame.LookVector * Vector3.new(1, 0, 1)
			if look.Magnitude < 0.1 then
				look = Vector3.new(0, 0, -1)
			end
			local position = car:GetPivot().Position + Vector3.new(0, 5, 0)
			car:PivotTo(CFrame.lookAt(position, position + look.Unit))
			seat.AssemblyLinearVelocity = Vector3.zero
			seat.AssemblyAngularVelocity = Vector3.zero
			tippedSince = nil
		end
	else
		tippedSince = nil
	end
end
