-- @title FPS counter
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords fps counter, frames per second, lag meter, performance display, frame rate
-- @about Shows how many frames per second your game is running at in the top corner, colored green, yellow or red.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "FPS"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(1, 0)
label.Position = UDim2.new(1, -10, 0, 10)
label.Size = UDim2.fromOffset(110, 28)
label.BackgroundTransparency = 0.4
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.Font = Enum.Font.Code
label.TextScaled = true
label.Parent = gui

local frames = 0
local timer = 0
RunService.RenderStepped:Connect(function(deltaTime)
	frames += 1
	timer += deltaTime
	if timer >= 0.5 then -- update twice a second so it is easy to read
		local fps = math.floor(frames / timer + 0.5)
		label.Text = fps .. " FPS"
		if fps >= 50 then
			label.TextColor3 = Color3.fromRGB(90, 230, 90)
		elseif fps >= 30 then
			label.TextColor3 = Color3.fromRGB(240, 220, 60)
		else
			label.TextColor3 = Color3.fromRGB(240, 70, 70)
		end
		frames, timer = 0, 0
	end
end)
