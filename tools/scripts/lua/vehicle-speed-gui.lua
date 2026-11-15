-- @title Speedometer
-- @category Vehicles
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords speedometer, vehicle speed display, mph gauge, driving hud, car dashboard
-- @about While you sit in any VehicleSeat, shows how fast you are going (and the fuel, if the car has the fuel script).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Speedometer"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(1, 1)
label.Position = UDim2.new(1, -20, 1, -20)
label.Size = UDim2.fromOffset(200, 80)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
label.BackgroundTransparency = 0.3
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.Parent = gui
Instance.new("UICorner", label)

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if not seat or not seat:IsA("VehicleSeat") then
		gui.Enabled = false
		return
	end
	gui.Enabled = true
	-- Roblox says 1 stud is about 0.28 meters, so studs per second times about 0.63 is roughly mph
	local mph = math.floor(seat.AssemblyLinearVelocity.Magnitude * 0.63)
	local text = mph .. " mph"
	local car = seat:FindFirstAncestorOfClass("Model")
	local fuel = car and car:GetAttribute("Fuel")
	if fuel then
		text ..= "\nFuel " .. math.floor(fuel) .. "%"
	end
	label.Text = text
end)
