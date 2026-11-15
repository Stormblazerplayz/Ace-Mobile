-- @title Landmine
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a small flat Anchored Part on the ground (the mine).
-- @keywords landmine, mine trap, step on a mine, hidden explosive, beeping mine
-- @about Beeps and blinks red; whoever steps on it gets blown into the air, then it re-arms after a while.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local DAMAGE = 50
local BLAST_RADIUS = 8
local REARM_TIME = 15
local HIDDEN = false -- true = nearly invisible

local mine = script.Parent
mine.Anchored = true
mine.CanCollide = false
mine.Transparency = HIDDEN and 0.9 or 0
local light = Instance.new("PointLight")
light.Color = Color3.fromRGB(255, 0, 0)
light.Range = 4
light.Parent = mine
local armed = true

mine.Touched:Connect(function(hit)
	if not armed or not Players:GetPlayerFromCharacter(hit.Parent) then
		return
	end
	armed = false
	local boom = Instance.new("Explosion")
	boom.Position = mine.Position
	boom.BlastRadius = BLAST_RADIUS
	boom.BlastPressure = 300000 -- big push
	boom.DestroyJointRadiusPercent = 0
	local hurt = {}
	boom.Hit:Connect(function(part)
		local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and not hurt[humanoid] then
			hurt[humanoid] = true
			humanoid:TakeDamage(DAMAGE)
		end
	end)
	boom.Parent = workspace
	mine.Transparency = 1
	light.Enabled = false
	task.wait(REARM_TIME)
	mine.Transparency = HIDDEN and 0.9 or 0
	light.Enabled = true
	armed = true
end)

-- Blink the little red light
while true do
	if armed then
		light.Enabled = not light.Enabled
	end
	task.wait(0.5)
end
