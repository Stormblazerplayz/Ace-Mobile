-- @title Rebirth button
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. It needs the Rebirth system server script (Rebirth RemoteEvent and RebirthCost attribute).
-- @keywords rebirth button, rebirth gui, prestige button, reset for bonus, rebirth cost display
-- @about A button that shows how much a rebirth costs, turns green when you can afford it, and asks the server to rebirth you.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local rebirth = ReplicatedStorage:WaitForChild("Rebirth")
local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")

local gui = Instance.new("ScreenGui")
gui.Name = "RebirthButton"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 1)
button.Position = UDim2.new(1, -16, 1, -90)
button.Size = UDim2.fromOffset(200, 60)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = gui
Instance.new("UICorner", button)

local function update()
	local cost = player:GetAttribute("RebirthCost") or 0
	button.Text = "Rebirth\n" .. cost .. " coins"
	if coins.Value >= cost then
		button.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
	else
		button.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
	end
end

button.Activated:Connect(function()
	-- The server checks the coins again; we just ask
	rebirth:FireServer()
end)

coins.Changed:Connect(update)
player:GetAttributeChangedSignal("RebirthCost"):Connect(update)
update()
