-- @title Announcement banner
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Any server script can show a message with workspace:SetAttribute("Announcement", "Your text").
-- @keywords announcement banner, server message, big message top, slide in banner, broadcast text
-- @about A banner slides down from the top of everyone's screen with the server's announcement, then slides away.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change this!
local SHOW_TIME = 5

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Announcement"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 1)
banner.Position = UDim2.new(0.5, 0, 0, -10) -- hidden above the screen
banner.Size = UDim2.new(0.6, 0, 0, 60)
banner.BackgroundColor3 = Color3.fromRGB(250, 190, 40)
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.TextColor3 = Color3.fromRGB(40, 25, 0)
banner.Parent = gui
Instance.new("UICorner", banner)

local count = 0
workspace:GetAttributeChangedSignal("Announcement"):Connect(function()
	local text = workspace:GetAttribute("Announcement")
	if type(text) ~= "string" or text == "" then
		return
	end
	count += 1
	local myCount = count
	banner.Text = text
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 80) }):Play()
	task.wait(SHOW_TIME)
	if count == myCount then -- only hide if no newer message came
		TweenService:Create(banner, TweenInfo.new(0.4), { Position = UDim2.new(0.5, 0, 0, -10) }):Play()
	end
end)
