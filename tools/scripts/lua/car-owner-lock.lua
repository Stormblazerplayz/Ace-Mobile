-- @title Only the owner can drive
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a car Model that has a VehicleSeat. The Car spawner pad sets the Owner attribute; you can also set it yourself to a UserId.
-- @keywords car lock, owner only seat, my car only, vehicle ownership, kick out of driver seat
-- @about If anyone except the car's owner sits in the driver's seat, they get popped back out with a message.

local Players = game:GetService("Players")

local car = script.Parent
local seat = car:FindFirstChildWhichIsA("VehicleSeat", true)

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	local humanoid = seat.Occupant
	if not humanoid then
		return
	end
	local player = Players:GetPlayerFromCharacter(humanoid.Parent)
	local owner = car:GetAttribute("Owner")
	if owner and player and player.UserId ~= owner then
		-- Break the seat weld to make them stand up
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		humanoid.Sit = false
		humanoid.Jump = true
		player:SetAttribute("Notice", "This is not your car!")
	end
end)
