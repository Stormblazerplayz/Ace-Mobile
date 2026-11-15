-- @title Tycoon buy buttons
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside your tycoon Model; add a Folder named Items (things to buy) and a Folder named Buttons whose Parts have a number Attribute Price and a text Attribute Item (the name of a thing in Items).
-- @keywords tycoon buttons, buy button tycoon, unlock items, purchase walls and droppers, tycoon upgrades
-- @about Hides everything in Items until the owner steps on its button and pays for it, then the thing appears.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local STAT_NAME = "Coins"

local tycoon = script.Parent
local owner = tycoon:WaitForChild("Owner")
local items = tycoon:WaitForChild("Items")
local buttons = tycoon:WaitForChild("Buttons")

-- Hide the items in ServerStorage until they are bought
local hidden = Instance.new("Folder")
hidden.Name = tycoon.Name .. "_Hidden"
hidden.Parent = ServerStorage
for _, item in ipairs(items:GetChildren()) do
	item.Parent = hidden
end

local function setupButton(button)
	local itemName = button:GetAttribute("Item")
	local price = button:GetAttribute("Price") or 0
	-- Show the price on a little sign
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(160, 40)
	sign.StudsOffset = Vector3.new(0, 3, 0)
	sign.Parent = button
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = tostring(itemName) .. ": $" .. price
	label.Parent = sign

	local bought = false
	button.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if bought or not player or player ~= owner.Value then
			return
		end
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild(STAT_NAME)
		local item = hidden:FindFirstChild(itemName)
		if not coins or not item or coins.Value < price then
			return
		end
		bought = true
		coins.Value = coins.Value - price
		item.Parent = items -- it appears!
		button:Destroy()
	end)
end

for _, button in ipairs(buttons:GetChildren()) do
	if button:IsA("BasePart") then
		setupButton(button)
	end
end
