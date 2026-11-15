-- @title Custom loading screen
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in ReplicatedFirst (it has to be there to show up before everything else loads).
-- @keywords loading screen, custom loading, loading bar, game is loading, intro screen
-- @about Replaces the Roblox loading screen with your own one that has a spinning icon and a loading bar.

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

-- Settings: change these!
local GAME_NAME = "My Game"
local MIN_TIME = 2 -- show it at least this long so it does not just flash

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(20, 22, 35)
background.Parent = gui

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.4)
title.Size = UDim2.fromScale(0.7, 0.12)
title.BackgroundTransparency = 1
title.Text = GAME_NAME
title.TextScaled = true
title.Font = Enum.Font.FredokaOne
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = background

local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.6)
barBack.Size = UDim2.fromScale(0.4, 0.02)
barBack.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
barBack.Parent = background
local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(90, 170, 255)
bar.BorderSizePixel = 0
bar.Parent = barBack

local started = os.clock()
local startQueue = math.max(ContentProvider.RequestQueueSize, 1)
-- Fill the bar as the download queue gets smaller
while not game:IsLoaded() or ContentProvider.RequestQueueSize > 0 or os.clock() - started < MIN_TIME do
	local done = 1 - ContentProvider.RequestQueueSize / startQueue
	local timeDone = (os.clock() - started) / MIN_TIME
	bar.Size = UDim2.fromScale(math.clamp(math.min(done, timeDone), 0.05, 1), 1)
	task.wait(0.1)
	if os.clock() - started > 20 then
		break -- never get stuck forever
	end
end
bar.Size = UDim2.fromScale(1, 1)
task.wait(0.3)

TweenService:Create(background, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
TweenService:Create(title, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
barBack.Visible = false
task.wait(0.6)
gui:Destroy()
