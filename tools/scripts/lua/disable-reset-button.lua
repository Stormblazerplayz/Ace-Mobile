-- @title Turn off the reset button
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords disable reset, no reset button, cant reset character, turn off reset, block resetting
-- @about Turns off the Reset Character button in the Roblox menu so players cannot reset.

local StarterGui = game:GetService("StarterGui")

-- The Roblox menu might not be ready yet, so keep trying for a few seconds
for _ = 1, 20 do
	local ok = pcall(function()
		StarterGui:SetCore("ResetButtonCallback", false)
	end)
	if ok then
		break
	end
	task.wait(0.5)
end
