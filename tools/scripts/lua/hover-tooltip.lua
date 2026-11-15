-- @title Tooltips when you hover
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts, then give any button or frame a text Attribute named Tooltip.
-- @keywords tooltip, hover text, mouse over info, item description popup, hint text
-- @about Shows a little info box next to the mouse when you hover over any GUI that has a Tooltip attribute.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "Tooltip"
gui.DisplayOrder = 50
gui.ResetOnSpawn = false
gui.Parent = playerGui

local box = Instance.new("TextLabel")
box.AutomaticSize = Enum.AutomaticSize.XY
box.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
box.BackgroundTransparency = 0.1
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Gotham
box.TextSize = 16
box.Visible = false
box.Parent = gui
Instance.new("UICorner", box)
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
pad.Parent = box

local hovering = nil

local function hook(object)
	if not object:IsA("GuiObject") then
		return
	end
	object.MouseEnter:Connect(function()
		local tip = object:GetAttribute("Tooltip")
		if tip then
			hovering = object
			box.Text = tostring(tip)
			box.Visible = true
		end
	end)
	object.MouseLeave:Connect(function()
		if hovering == object then
			hovering = nil
			box.Visible = false
		end
	end)
end

for _, object in ipairs(playerGui:GetDescendants()) do
	hook(object)
end
playerGui.DescendantAdded:Connect(hook)

-- Follow the mouse
RunService.RenderStepped:Connect(function()
	if box.Visible then
		local mouse = UserInputService:GetMouseLocation()
		box.Position = UDim2.fromOffset(mouse.X + 16, mouse.Y - 30)
	end
end)
