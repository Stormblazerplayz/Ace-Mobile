-- @title Car boost pad
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside an anchored, flat Part on your road. Point the part's front face the way cars should be launched.
-- @keywords nitro boost, car boost pad, race boost, vehicle speed pad, turbo strip
-- @about Any car that drives over the pad gets a big push forward in the pad's direction, perfect for race tracks.

-- Settings: change these!
local BOOST_SPEED = 150
local COOLDOWN = 1 -- seconds before the same car can boost again

local pad = script.Parent
pad.Material = Enum.Material.Neon
local recent = {}

pad.Touched:Connect(function(hit)
	-- Find the car's seat to know this is a vehicle
	local car = hit:FindFirstAncestorOfClass("Model")
	local seat = car and car:FindFirstChildWhichIsA("VehicleSeat", true)
	if not seat or not seat.Occupant then
		return
	end
	if os.clock() - (recent[car] or 0) < COOLDOWN then
		return
	end
	recent[car] = os.clock()
	-- Keep the car's up and down speed, but replace forward speed with a boost
	local current = seat.AssemblyLinearVelocity
	local boost = pad.CFrame.LookVector * BOOST_SPEED
	seat.AssemblyLinearVelocity = Vector3.new(boost.X, current.Y, boost.Z)
	task.delay(COOLDOWN * 2, function()
		recent[car] = nil
	end)
end)
