-- @title Music volume slider
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Music scripts should play their sounds in a SoundGroup named Music in SoundService (this script makes one).
-- @keywords volume slider, music volume, sound slider, louder quieter, audio settings
-- @about A slider bar players drag to make the music louder or quieter, just for themselves.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- A SoundGroup is like a volume knob for many sounds at once
local group = SoundService:FindFirstChild("Music") or Instance.new("SoundGroup")
group.Name = "Music"
group.Parent = SoundService
-- Put any looping sounds into the group automatically
for _, sound in ipairs(SoundService:GetDescendants()) do
	if sound:IsA("Sound") and not sound.SoundGroup then
		sound.SoundGroup = group
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "VolumeSlider"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0, 1)
bar.Position = UDim2.new(0, 20, 1, -30)
bar.Size = UDim2.fromOffset(200, 10)
bar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
bar.Parent = gui

local knob = Instance.new("TextButton")
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Size = UDim2.fromOffset(24, 24)
knob.Text = ""
knob.BackgroundColor3 = Color3.fromRGB(240, 240, 255)
knob.Parent = bar
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local label = Instance.new("TextLabel")
label.Position = UDim2.fromOffset(0, -26)
label.Size = UDim2.fromOffset(200, 20)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Font = Enum.Font.GothamBold
label.TextSize = 16
label.Parent = bar

local function setVolume(fraction)
	fraction = math.clamp(fraction, 0, 1)
	knob.Position = UDim2.fromScale(fraction, 0.5)
	group.Volume = fraction
	label.Text = "Music " .. math.floor(fraction * 100) .. "%"
end

local dragging = false
knob.MouseButton1Down:Connect(function()
	dragging = true
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local x = input.Position.X - bar.AbsolutePosition.X
		setVolume(x / bar.AbsoluteSize.X)
	end
end)

setVolume(0.5)
