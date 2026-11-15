-- @title Car headlights
-- @category Vehicles
-- @kind Script
-- @where Put this Script inside a car Model with a VehicleSeat. Name the front light parts Headlight (any number of them).
-- @keywords headlights, car lights, toggle lights, night driving, vehicle lights
-- @about The driver presses L to turn the headlights on and off; they glow and shine a real beam of light ahead.

local Players = game:GetService("Players")

local car = script.Parent
local seat = car:FindFirstChildWhichIsA("VehicleSeat", true)

-- Set up every Headlight part with a SpotLight shining forward
local lights = {}
for _, part in ipairs(car:GetDescendants()) do
	if part:IsA("BasePart") and part.Name == "Headlight" then
		local spot = part:FindFirstChildOfClass("SpotLight") or Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Front
		spot.Range = 40
		spot.Angle = 60
		spot.Brightness = 3
		spot.Enabled = false
		spot.Parent = part
		table.insert(lights, { part = part, spot = spot })
	end
end

local on = false
local function setLights(state)
	on = state
	for _, light in ipairs(lights) do
		light.spot.Enabled = on
		light.part.Material = on and Enum.Material.Neon or Enum.Material.Glass
	end
end

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Lights"
prompt.KeyboardKeyCode = Enum.KeyCode.L
prompt.MaxActivationDistance = 6
prompt.RequiresLineOfSight = false
prompt.Enabled = false
prompt.Parent = seat

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	prompt.Enabled = seat.Occupant ~= nil
end)

prompt.Triggered:Connect(function(player)
	local humanoid = seat.Occupant
	if humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) == player then
		setLights(not on)
	end
end)

setLights(false)
