-- @title Pop-up notifications
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts; server scripts show a message with player:SetAttribute("Notice", "Hello!").
-- @keywords notifications, toast messages, popup message, notify player, message on screen, alerts
-- @about Shows little messages that slide in at the top right and fade away; many other scripts here use the Notice attribute to talk to players.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these!
local SHOW_TIME = 3.5
local MAX_ON_SCREEN = 4

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Notifications"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(1, 0)
holder.Position = UDim2.new(1, -16, 0, 16)
holder.Size = UDim2.fromOffset(300, 400)
holder.BackgroundTransparency = 1
holder.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = holder

local count = 0

local function notify(text)
	count += 1
	local toast = Instance.new("TextLabel")
	toast.LayoutOrder = count
	toast.Size = UDim2.fromOffset(300, 46)
	toast.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	toast.BackgroundTransparency = 1
	toast.TextTransparency = 1
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.TextScaled = true
	toast.Font = Enum.Font.GothamMedium
	toast.Text = text
	toast.Parent = holder
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = toast

	-- Too many? remove the oldest
	local toasts = {}
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	if #toasts > MAX_ON_SCREEN then
		toasts[1]:Destroy()
	end

	TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 0.15, TextTransparency = 0 }):Play()
	task.delay(SHOW_TIME, function()
		local fade = TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		toast:Destroy()
	end)
end

-- Server scripts set the "Notice" attribute on the player
player:GetAttributeChangedSignal("Notice"):Connect(function()
	local text = player:GetAttribute("Notice")
	if typeof(text) == "string" and text ~= "" then
		notify(text)
	end
end)
