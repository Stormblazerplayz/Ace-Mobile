-- @title Speed coil
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part and put the Tool in StarterPack (or sell it in a shop).
-- @keywords speed coil, run faster tool, speed gear, fast coil, classic coil
-- @about While you hold the speed coil you run much faster; put it away and you go back to normal.

-- Settings: change this number!
local SPEED_MULTIPLIER = 1.75

local tool = script.Parent
local humanoid = nil
local normalSpeed = 16

tool.Equipped:Connect(function()
	humanoid = tool.Parent and tool.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		normalSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = normalSpeed * SPEED_MULTIPLIER
	end
end)

tool.Unequipped:Connect(function()
	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = normalSpeed
	end
	humanoid = nil
end)
