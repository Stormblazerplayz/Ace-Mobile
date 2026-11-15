-- @title Click to get a tool
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Part, and put the Tool you want to give in ServerStorage (set TOOL_NAME to its exact name).
-- @keywords give tool, click to get item, tool giver, free item part, get a sword by clicking
-- @about Clicking or tapping the part puts a copy of the tool in the player's backpack.

local ServerStorage = game:GetService("ServerStorage")

-- Settings: change these!
local TOOL_NAME = "Sword" -- the exact name of the Tool in ServerStorage
local CLICK_DISTANCE = 20 -- how close you must be to click it

local part = script.Parent

-- Add a ClickDetector so the part can be clicked or tapped
local clickDetector = part:FindFirstChildOfClass("ClickDetector") or Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = CLICK_DISTANCE
clickDetector.Parent = part

clickDetector.MouseClick:Connect(function(player)
	local tool = ServerStorage:FindFirstChild(TOOL_NAME)
	if not tool then
		warn("Put a Tool named " .. TOOL_NAME .. " in ServerStorage!")
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	if not backpack then
		return
	end

	-- Only one each, no stacking up copies
	if backpack:FindFirstChild(TOOL_NAME) or (character and character:FindFirstChild(TOOL_NAME)) then
		return
	end

	tool:Clone().Parent = backpack
end)
