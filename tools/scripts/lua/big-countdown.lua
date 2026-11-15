-- @title Big countdown numbers
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. A server script starts it with workspace:SetAttribute("Countdown", 3).
-- @keywords big countdown, 3 2 1 go, race start numbers, countdown popup, start countdown
-- @about When the server sets the Countdown attribute, giant numbers pop up in the middle of the screen counting down to GO!

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Countdown"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.4)
label.Size = UDim2.fromScale(0.4, 0.25)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 220, 60)
label.TextStrokeTransparency = 0
label.Visible = false
label.Parent = gui
local scale = Instance.new("UIScale")
scale.Parent = label

local function pop(text)
	label.Text = text
	label.Visible = true
	label.TextTransparency = 0
	scale.Scale = 1.8
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local running = 0
workspace:GetAttributeChangedSignal("Countdown"):Connect(function()
	local start = workspace:GetAttribute("Countdown")
	if type(start) ~= "number" or start <= 0 then
		return
	end
	running += 1
	local myRun = running
	for n = start, 1, -1 do
		if running ~= myRun then
			return -- a new countdown started
		end
		pop(tostring(n))
		task.wait(1)
	end
	pop("GO!")
	task.wait(0.8)
	TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
end)
