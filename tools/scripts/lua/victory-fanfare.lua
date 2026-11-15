-- @title Victory sound when you win
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and paste a short win jingle id into FANFARE_ID. It listens to your leaderstats Wins.
-- @keywords victory sound, win jingle, fanfare, winner music, celebration sound
-- @about Plays a happy fanfare and shows "VICTORY!" on your screen every time your Wins number goes up.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Settings: paste your sound id
local FANFARE_ID = ""

local player = Players.LocalPlayer
local wins = player:WaitForChild("leaderstats"):WaitForChild("Wins")

local fanfare = Instance.new("Sound")
fanfare.SoundId = FANFARE_ID
fanfare.Volume = 0.8
fanfare.Parent = SoundService

local gui = Instance.new("ScreenGui")
gui.Name = "Victory"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.3)
label.Size = UDim2.fromScale(0.6, 0.15)
label.BackgroundTransparency = 1
label.Text = "VICTORY!"
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 215, 60)
label.TextStrokeTransparency = 0
label.TextTransparency = 1
label.Parent = gui

local last = wins.Value
wins.Changed:Connect(function(value)
	if value > last then
		if FANFARE_ID ~= "" then
			fanfare:Play()
		end
		label.TextTransparency = 0
		task.delay(2, function()
			TweenService:Create(label, TweenInfo.new(1), { TextTransparency = 1 }):Play()
		end)
	end
	last = value
end)
