-- @title Code redeem box
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. It needs the Redeem codes server script (which makes the RedeemCode RemoteFunction).
-- @keywords redeem box, enter code gui, code textbox, twitter codes menu, promo code input
-- @about A text box and Redeem button where players type codes; it shows a green or red message with the answer from the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local redeem = ReplicatedStorage:WaitForChild("RedeemCode")

local gui = Instance.new("ScreenGui")
gui.Name = "Codes"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(0, 1)
box.Position = UDim2.new(0, 16, 1, -90)
box.Size = UDim2.fromOffset(260, 110)
box.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
box.Parent = gui
Instance.new("UICorner", box)

local input = Instance.new("TextBox")
input.Position = UDim2.fromOffset(10, 10)
input.Size = UDim2.new(1, -20, 0, 36)
input.PlaceholderText = "Type a code..."
input.Text = ""
input.ClearTextOnFocus = false
input.TextScaled = true
input.Font = Enum.Font.Gotham
input.Parent = box

local button = Instance.new("TextButton")
button.Position = UDim2.fromOffset(10, 52)
button.Size = UDim2.new(0.45, 0, 0, 36)
button.Text = "Redeem"
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = box

local message = Instance.new("TextLabel")
message.Position = UDim2.new(0.5, 5, 0, 52)
message.Size = UDim2.new(0.5, -15, 0, 50)
message.BackgroundTransparency = 1
message.TextWrapped = true
message.TextScaled = true
message.Font = Enum.Font.Gotham
message.Text = ""
message.Parent = box

local busy = false
button.Activated:Connect(function()
	if busy or input.Text == "" then
		return
	end
	busy = true
	message.Text = "Checking..."
	message.TextColor3 = Color3.new(1, 1, 1)
	-- InvokeServer waits for the server's answer
	local ok, success, reply = pcall(function()
		return redeem:InvokeServer(input.Text)
	end)
	if ok then
		message.Text = tostring(reply or (success and "Redeemed!" or "Nope"))
		message.TextColor3 = success and Color3.fromRGB(90, 230, 90) or Color3.fromRGB(240, 80, 80)
		if success then
			input.Text = ""
		end
	else
		message.Text = "Try again later"
	end
	busy = false
end)
