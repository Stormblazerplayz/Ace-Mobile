-- @title Main menu with Play button
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts; optional: add an Anchored Part named MenuCamera in Workspace where the menu camera should look from.
-- @keywords main menu, title screen, play button, start menu, menu screen
-- @about Shows your game's title and a big Play button over a blurred view of your map until the player presses Play.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- Settings: change these!
local GAME_TITLE = "My Awesome Game"
local SUBTITLE = "Made by me!"

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local menuCameraPart = workspace:FindFirstChild("MenuCamera")

local blur = Instance.new("BlurEffect")
blur.Size = 18
blur.Parent = Lighting

local gui = Instance.new("ScreenGui")
gui.Name = "MainMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 0.5
shade.Parent = gui

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.3)
title.Size = UDim2.fromScale(0.8, 0.15)
title.BackgroundTransparency = 1
title.Text = GAME_TITLE
title.TextScaled = true
title.Font = Enum.Font.FredokaOne
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = shade

local subtitle = title:Clone()
subtitle.Position = UDim2.fromScale(0.5, 0.42)
subtitle.Size = UDim2.fromScale(0.6, 0.06)
subtitle.Text = SUBTITLE
subtitle.Parent = shade

local play = Instance.new("TextButton")
play.AnchorPoint = Vector2.new(0.5, 0.5)
play.Position = UDim2.fromScale(0.5, 0.65)
play.Size = UDim2.fromOffset(240, 70)
play.Text = "PLAY"
play.TextScaled = true
play.Font = Enum.Font.FredokaOne
play.BackgroundColor3 = Color3.fromRGB(70, 200, 100)
play.TextColor3 = Color3.new(1, 1, 1)
play.Parent = shade
Instance.new("UICorner", play).CornerRadius = UDim.new(0, 16)

-- Point the camera at the menu view (if you made a MenuCamera part)
if menuCameraPart then
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = menuCameraPart.CFrame
end

play.Activated:Connect(function()
	play.Active = false
	TweenService:Create(shade, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(blur, TweenInfo.new(0.5), { Size = 0 }):Play()
	for _, label in ipairs({ title, subtitle, play }) do
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
	end
	TweenService:Create(play, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	task.wait(0.5)
	camera.CameraType = Enum.CameraType.Custom -- normal camera again
	gui:Destroy()
	blur:Destroy()
end)
