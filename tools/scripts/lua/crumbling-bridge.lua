-- @title Crumbling bridge
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside a Model or Folder that holds all the Anchored plank Parts of your bridge.
-- @keywords crumbling bridge, planks fall, breaking bridge, bridge falls apart, run across the bridge
-- @about Each plank turns red and falls a moment after someone steps on it, then grows back later.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local FALL_DELAY = 0.5 -- seconds after touching before the plank drops
local RESPAWN_TIME = 5 -- seconds before the plank comes back
local WARNING_COLOR = Color3.fromRGB(200, 60, 40)

local function setupPlank(plank)
	local home = plank.CFrame
	local normalColor = plank.Color
	local falling = false

	plank.Touched:Connect(function(hit)
		if falling or not Players:GetPlayerFromCharacter(hit.Parent) then
			return
		end
		falling = true
		plank.Color = WARNING_COLOR
		task.wait(FALL_DELAY)

		-- Let gravity take it
		plank.Anchored = false
		plank.CanCollide = false
		task.wait(RESPAWN_TIME)

		-- Grow back
		plank.Anchored = true
		plank.CFrame = home
		plank.Color = normalColor
		plank.CanCollide = true
		falling = false
	end)
end

for _, child in ipairs(script.Parent:GetChildren()) do
	if child:IsA("BasePart") then
		setupPlank(child)
	end
end
