-- @title XP bar
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Works with the XP and levels script (player attributes XP and XPNeeded, leaderstats Level).
-- @keywords xp bar, experience bar, level progress, level up bar, exp meter
-- @about Shows a bar at the bottom of the screen that fills up as you earn XP, with your level written on it.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "XPBar"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local back = Instance.new("Frame")
back.AnchorPoint = Vector2.new(0.5, 1)
back.Position = UDim2.new(0.5, 0, 1, -12)
back.Size = UDim2.new(0.5, 0, 0, 24)
back.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
back.Parent = gui
Instance.new("UICorner", back)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
fill.Parent = back
Instance.new("UICorner", fill)

local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundTransparency = 1
text.Font = Enum.Font.GothamBold
text.TextScaled = true
text.TextColor3 = Color3.new(1, 1, 1)
text.Parent = back

local function update()
	local xp = player:GetAttribute("XP") or 0
	local needed = player:GetAttribute("XPNeeded") or 100
	local stats = player:FindFirstChild("leaderstats")
	local level = stats and stats:FindFirstChild("Level")
	local fraction = math.clamp(xp / math.max(needed, 1), 0, 1)
	TweenService:Create(fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(fraction, 1) }):Play()
	text.Text = "Level " .. (level and level.Value or 1) .. "   " .. xp .. " / " .. needed .. " XP"
end

player:GetAttributeChangedSignal("XP"):Connect(update)
player:GetAttributeChangedSignal("XPNeeded"):Connect(update)
local stats = player:WaitForChild("leaderstats", 10)
local level = stats and stats:WaitForChild("Level", 10)
if level then
	level.Changed:Connect(update)
end
update()
