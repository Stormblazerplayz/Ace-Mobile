-- @title Settings menu
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords settings menu, options menu, toggle music, turn off shadows, game settings gui
-- @about A gear button that opens a settings menu with switches for music, shadows and particles (each player's own choice).

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Settings"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local gear = Instance.new("TextButton")
gear.Position = UDim2.new(0, 16, 0.5, 0)
gear.Size = UDim2.fromOffset(50, 50)
gear.Text = "Settings"
gear.TextScaled = true
gear.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
gear.TextColor3 = Color3.new(1, 1, 1)
gear.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(300, 220)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel)
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 10)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Parent = panel
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 15)
pad.Parent = panel

-- Makes an ON/OFF switch button. onChange gets true or false.
local function makeToggle(name, startOn, onChange)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(260, 50)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = panel
	local on = startOn
	local function refresh()
		button.Text = name .. ": " .. (on and "ON" or "OFF")
		button.BackgroundColor3 = on and Color3.fromRGB(60, 170, 90) or Color3.fromRGB(150, 60, 60)
	end
	button.Activated:Connect(function()
		on = not on
		refresh()
		onChange(on)
	end)
	refresh()
end

makeToggle("Music", true, function(on)
	-- Music scripts can check this attribute; we also mute every looped sound
	player:SetAttribute("MusicMuted", not on)
	for _, sound in ipairs(SoundService:GetDescendants()) do
		if sound:IsA("Sound") and sound.Looped then
			sound.Volume = on and (sound:GetAttribute("NormalVolume") or 0.5) or 0
		end
	end
end)
makeToggle("Shadows", Lighting.GlobalShadows, function(on)
	Lighting.GlobalShadows = on -- changed only for you
end)
makeToggle("Particles", true, function(on)
	for _, emitter in ipairs(workspace:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = on
		end
	end
end)

gear.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
