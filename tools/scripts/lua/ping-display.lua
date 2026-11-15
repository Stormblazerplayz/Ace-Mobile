-- @title Ping display
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords ping display, network lag, connection speed, latency meter, ms ping
-- @about Shows your ping (how long messages take to reach the server) in milliseconds.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Ping"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(1, 0)
label.Position = UDim2.new(1, -10, 0, 42)
label.Size = UDim2.fromOffset(110, 28)
label.BackgroundTransparency = 0.4
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.Font = Enum.Font.Code
label.TextScaled = true
label.Parent = gui

while true do
	-- GetNetworkPing gives one-way time in seconds, so times 2 for there and back, times 1000 for ms
	local ms = math.floor(player:GetNetworkPing() * 2000)
	label.Text = ms .. " ms"
	if ms < 100 then
		label.TextColor3 = Color3.fromRGB(90, 230, 90)
	elseif ms < 250 then
		label.TextColor3 = Color3.fromRGB(240, 220, 60)
	else
		label.TextColor3 = Color3.fromRGB(240, 70, 70)
	end
	task.wait(1)
end
