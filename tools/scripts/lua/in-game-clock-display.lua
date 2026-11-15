-- @title Game time clock on screen
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Works best with a day and night cycle script.
-- @keywords clock display, time of day text, in game time, am pm clock, world clock gui
-- @about Shows the in-game time (from Lighting.ClockTime) like "7:30 PM" with a sun or moon word.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "GameClock"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 44)
label.Size = UDim2.fromOffset(180, 32)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.BackgroundTransparency = 0.5
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.Parent = gui

local function update()
	local time = Lighting.ClockTime -- 0 to 24
	local hours = math.floor(time)
	local minutes = math.floor((time - hours) * 60)
	local suffix = hours >= 12 and "PM" or "AM"
	local shownHours = hours % 12
	if shownHours == 0 then
		shownHours = 12
	end
	local isDay = time >= 6 and time < 18
	label.Text = string.format("%d:%02d %s  %s", shownHours, minutes, suffix, isDay and "Day" or "Night")
end

Lighting:GetPropertyChangedSignal("ClockTime"):Connect(update)
update()
