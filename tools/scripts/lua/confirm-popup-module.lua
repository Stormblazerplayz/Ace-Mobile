-- @title Yes or No popup (module)
-- @category GUI
-- @kind ModuleScript
-- @where Put this ModuleScript in ReplicatedStorage and name it ConfirmPopup; LocalScripts use require(game.ReplicatedStorage.ConfirmPopup).Ask("Buy this?").
-- @keywords confirm popup, yes no dialog, are you sure, confirmation box, purchase confirm
-- @about A module that shows an "Are you sure?" box with Yes and No buttons and gives back true or false.

local Players = game:GetService("Players")

local ConfirmPopup = {}

-- Ask(question) waits until the player clicks, then returns true (Yes) or false (No)
function ConfirmPopup.Ask(question)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "ConfirmPopup"
	gui.DisplayOrder = 100
	gui.Parent = player:WaitForChild("PlayerGui")

	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromOffset(320, 160)
	box.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	box.Parent = gui
	Instance.new("UICorner", box)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 80)
	label.Position = UDim2.fromOffset(10, 5)
	label.BackgroundTransparency = 1
	label.Text = question
	label.TextWrapped = true
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = box

	local answered = Instance.new("BindableEvent")
	local function makeButton(text, color, xScale, answer)
		local button = Instance.new("TextButton")
		button.AnchorPoint = Vector2.new(0.5, 0)
		button.Position = UDim2.new(xScale, 0, 0, 95)
		button.Size = UDim2.fromOffset(120, 50)
		button.Text = text
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.TextColor3 = Color3.new(1, 1, 1)
		button.BackgroundColor3 = color
		button.Parent = box
		Instance.new("UICorner", button)
		button.Activated:Connect(function()
			answered:Fire(answer)
		end)
	end
	makeButton("Yes", Color3.fromRGB(60, 170, 90), 0.28, true)
	makeButton("No", Color3.fromRGB(180, 60, 60), 0.72, false)

	local result = answered.Event:Wait()
	gui:Destroy()
	answered:Destroy()
	return result
end

return ConfirmPopup
