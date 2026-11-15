-- @title Keypad code door (screen part)
-- @category Doors and buttons
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts (use it with the Keypad code door server part).
-- @keywords keypad screen, type a code gui, code entry box, door code popup, keypad textbox
-- @about Shows a code box when you press E on a keypad and sends what you type to the server to check.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local currentModel = nil

-- Build the little popup
local gui = Instance.new("ScreenGui")
gui.Name = "KeypadGui"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromOffset(260, 150)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
frame.Parent = gui
Instance.new("UICorner").Parent = frame
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 50)
box.Position = UDim2.fromOffset(10, 10)
box.PlaceholderText = "Type the code"
box.Text = ""
box.TextScaled = true
box.ClearTextOnFocus = true
box.Parent = frame
local enter = Instance.new("TextButton")
enter.Size = UDim2.new(0.5, -15, 0, 50)
enter.Position = UDim2.new(0, 10, 0, 80)
enter.Text = "Enter"
enter.TextScaled = true
enter.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
enter.Parent = frame
local close = enter:Clone()
close.Position = UDim2.new(0.5, 5, 0, 80)
close.Text = "Close"
close.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
close.Parent = frame

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "KeypadPrompt" then
		currentModel = prompt.Parent.Parent
		box.Text = ""
		gui.Enabled = true
		box:CaptureFocus()
	end
end)

enter.Activated:Connect(function()
	local submit = currentModel and currentModel:FindFirstChild("SubmitCode")
	if not submit then
		return
	end
	local ok = submit:InvokeServer(box.Text)
	if ok then
		gui.Enabled = false
	else
		box.Text = ""
		box.PlaceholderText = "Wrong code!"
	end
end)

close.Activated:Connect(function()
	gui.Enabled = false
end)
