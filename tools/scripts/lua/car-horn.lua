-- @title Car horn
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside the car's VehicleSeat, and put a Sound named Horn inside the seat (pick a horn sound from the Toolbox and paste its id).
-- @keywords car horn, honk, beep beep, horn button, vehicle sound
-- @about The driver presses H (or taps the button on a phone) to honk the horn so everyone nearby hears it.

local Players = game:GetService("Players")

local seat = script.Parent
local horn = seat:FindFirstChild("Horn")

-- A ProximityPrompt only the driver will use; it works with keyboards and touch screens
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Honk"
prompt.KeyboardKeyCode = Enum.KeyCode.H
prompt.MaxActivationDistance = 6
prompt.RequiresLineOfSight = false
prompt.Enabled = false -- only on while someone is driving
prompt.Parent = seat

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	prompt.Enabled = seat.Occupant ~= nil
end)

local lastHonk = 0
prompt.Triggered:Connect(function(player)
	local humanoid = seat.Occupant
	-- Only the driver can honk, and not too often
	if not humanoid or Players:GetPlayerFromCharacter(humanoid.Parent) ~= player then
		return
	end
	if os.clock() - lastHonk < 0.6 then
		return
	end
	lastHonk = os.clock()
	if horn and horn.SoundId ~= "" then
		horn:Play()
	end
end)
