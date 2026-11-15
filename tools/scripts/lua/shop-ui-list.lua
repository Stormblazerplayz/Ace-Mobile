-- @title Shop window with item list
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. It uses the BuyItem RemoteEvent and the Shop (server part) script. Keep the ITEMS list the same as the server prices.
-- @keywords shop window, item shop gui, buy list, store menu, shop scroll list
-- @about Opens a shop window that lists every item and price, with a Buy button for each one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: what to show (the server decides the real price)
local ITEMS = {
	{ name = "Sword", price = 50 },
	{ name = "Speed Coil", price = 100 },
}

local player = Players.LocalPlayer
local buyItem = ReplicatedStorage:WaitForChild("BuyItem")

local gui = Instance.new("ScreenGui")
gui.Name = "ShopWindow"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.Position = UDim2.new(0, 16, 0.5, 60)
open.Size = UDim2.fromOffset(80, 50)
open.Text = "Shop"
open.TextScaled = true
open.Font = Enum.Font.GothamBold
open.BackgroundColor3 = Color3.fromRGB(240, 180, 40)
open.Parent = gui

local window = Instance.new("ScrollingFrame")
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.fromOffset(340, 300)
window.AutomaticCanvasSize = Enum.AutomaticSize.Y
window.CanvasSize = UDim2.new()
window.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
window.Visible = false
window.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = window

for _, item in ipairs(ITEMS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -10, 0, 50)
	row.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	row.Parent = window
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.6, 1)
	label.BackgroundTransparency = 1
	label.Text = item.name .. "  (" .. item.price .. ")"
	label.TextScaled = true
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = row
	local buy = Instance.new("TextButton")
	buy.Position = UDim2.fromScale(0.65, 0.1)
	buy.Size = UDim2.fromScale(0.32, 0.8)
	buy.Text = "Buy"
	buy.TextScaled = true
	buy.Font = Enum.Font.GothamBold
	buy.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
	buy.TextColor3 = Color3.new(1, 1, 1)
	buy.Parent = row
	buy.Activated:Connect(function()
		buyItem:FireServer(item.name) -- the server checks coins and gives the tool
	end)
end

open.Activated:Connect(function()
	window.Visible = not window.Visible
end)
