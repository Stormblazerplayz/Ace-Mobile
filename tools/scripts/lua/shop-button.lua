-- @title Shop button
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript inside a TextButton in a ScreenGui in StarterGui, and also add the Shop (server part) script and a RemoteEvent named BuyItem in ReplicatedStorage.
-- @keywords shop button, buy button, shop gui, buy with a button, store button
-- @about Tapping the button asks the server to buy an item, then shows if it worked.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change this to the item this button buys
local ITEM_NAME = "Sword" -- must match a name in the Shop (server part) PRICES list
local MESSAGE_TIME = 1.5 -- seconds the "Bought!" message stays

local button = script.Parent
local buyItem = ReplicatedStorage:WaitForChild("BuyItem")
local normalText = button.Text
local normalColor = button.BackgroundColor3
local messageNumber = 0

-- Tapping or clicking the button asks the server to buy (the server checks the coins)
button.Activated:Connect(function()
	buyItem:FireServer(ITEM_NAME)
end)

-- The server answers: did it work?
buyItem.OnClientEvent:Connect(function(itemName, success, message)
	if itemName ~= ITEM_NAME then
		return -- this answer is for a different button
	end
	messageNumber = messageNumber + 1
	local myNumber = messageNumber

	button.Text = message
	if success then
		button.BackgroundColor3 = Color3.fromRGB(60, 200, 90) -- green
	else
		button.BackgroundColor3 = Color3.fromRGB(220, 70, 70) -- red
	end

	-- Go back to normal after a moment
	task.delay(MESSAGE_TIME, function()
		if myNumber == messageNumber then
			button.Text = normalText
			button.BackgroundColor3 = normalColor
		end
	end)
end)
