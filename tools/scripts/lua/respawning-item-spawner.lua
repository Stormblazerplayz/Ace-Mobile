-- @title Item spawner pedestal
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside an Anchored pedestal Part and put the Tool you want inside the Script (as a child of the Script).
-- @keywords item spawner, weapon spawner, pedestal pickup, tool respawns, grab a weapon
-- @about Puts a Tool on top of the pedestal for players to grab; a new one appears a while after it is taken.

-- Settings: change this number!
local RESPAWN_TIME = 10

local pedestal = script.Parent
local template = script:FindFirstChildOfClass("Tool")
if not template then
	warn("Put a Tool inside this script!")
	return
end
template.Parent = nil -- keep the original safe

while true do
	local tool = template:Clone()
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		warn("The Tool needs a part named Handle")
		return
	end
	-- Float it above the pedestal
	handle.Anchored = true
	handle.CFrame = pedestal.CFrame * CFrame.new(0, pedestal.Size.Y / 2 + 2, 0)
	tool.Parent = workspace

	-- When someone picks it up, the tool moves into their character
	tool.AncestryChanged:Wait()
	handle.Anchored = false -- let it move with the player's hand
	task.wait(RESPAWN_TIME)
end
