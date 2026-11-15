-- @title Fall kill height
-- @category Obstacles
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords kill when falling, fall off the map, void kill, falling resets you, kill below height
-- @about Anyone who falls below a set height gets reset.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local KILL_HEIGHT = -50 -- fall lower than this Y position and you reset
local CHECK_EVERY = 0.25 -- seconds between checks

while true do
	task.wait(CHECK_EVERY)

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		-- Too low? Reset them!
		if root and humanoid and humanoid.Health > 0 and root.Position.Y < KILL_HEIGHT then
			humanoid.Health = 0
		end
	end
end
