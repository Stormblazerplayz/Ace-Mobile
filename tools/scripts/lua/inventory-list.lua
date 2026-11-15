-- @title Inventory list of your tools
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords inventory gui, backpack list, custom hotbar, item list, equip from list
-- @about Shows a list of every Tool you own on the left side; click one to hold it, click again to put it away.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Inventory"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 16, 0.25, 0)
list.Size = UDim2.fromOffset(180, 300)
list.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
list.BackgroundTransparency = 0.3
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ScrollBarThickness = 6
list.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.Parent = list

local function refresh()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	local tools = {}
	for _, holder in ipairs({ backpack, character }) do
		if holder then
			for _, tool in ipairs(holder:GetChildren()) do
				if tool:IsA("Tool") then
					table.insert(tools, tool)
				end
			end
		end
	end
	for _, tool in ipairs(tools) do
		local held = tool.Parent == character
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -8, 0, 36)
		button.Text = tool.Name
		button.TextScaled = true
		button.Font = Enum.Font.GothamMedium
		button.TextColor3 = Color3.new(1, 1, 1)
		button.BackgroundColor3 = held and Color3.fromRGB(70, 140, 220) or Color3.fromRGB(55, 55, 65)
		button.Parent = list
		button.Activated:Connect(function()
			if not humanoid then
				return
			end
			if tool.Parent == character then
				humanoid:UnequipTools()
			else
				humanoid:EquipTool(tool)
			end
		end)
	end
end

-- Refresh whenever tools move in or out of the backpack or hands
local function watch(holder)
	holder.ChildAdded:Connect(refresh)
	holder.ChildRemoved:Connect(refresh)
end
player.CharacterAdded:Connect(function(character)
	watch(character)
	watch(player:WaitForChild("Backpack"))
	refresh()
end)
if player.Character then
	watch(player.Character)
	watch(player:WaitForChild("Backpack"))
	refresh()
end
