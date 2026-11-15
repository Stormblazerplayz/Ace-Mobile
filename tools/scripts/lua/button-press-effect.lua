-- @title Pushable button with signal
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside an Anchored button Part; other scripts can listen to the BindableEvent named Pressed it makes inside the button.
-- @keywords pushable button, button sinks in, button event, bindable event button, reusable button
-- @about The button sinks in, lights up and clicks when pressed, then tells your other scripts through a Pressed event.

-- Settings: change these!
local PUSH_DEPTH = 0.3 -- how far it sinks in
local COOLDOWN = 1

local button = script.Parent
button.Anchored = true
local upCFrame = button.CFrame
local normalColor = button.Color

-- Other scripts do: button.Pressed.Event:Connect(function(player) ... end)
local pressed = Instance.new("BindableEvent")
pressed.Name = "Pressed"
pressed.Parent = button

local clicker = Instance.new("ClickDetector")
clicker.MaxActivationDistance = 15
clicker.Parent = button

local ready = true
local function press(player)
	if not ready then
		return
	end
	ready = false
	button.CFrame = upCFrame * CFrame.new(0, -PUSH_DEPTH, 0)
	button.Color = Color3.fromRGB(0, 255, 120)
	button.Material = Enum.Material.Neon
	pressed:Fire(player)
	task.wait(COOLDOWN)
	button.CFrame = upCFrame
	button.Color = normalColor
	button.Material = Enum.Material.SmoothPlastic
	ready = true
end

clicker.MouseClick:Connect(press)
button.Touched:Connect(function(hit)
	local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
	if player then
		press(player)
	end
end)
