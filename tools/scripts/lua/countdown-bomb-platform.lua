-- @title Bomb platform with countdown
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored Part that players stand on.
-- @keywords bomb platform, exploding platform, countdown explosion, ticking floor, platform blows up
-- @about Stepping on the platform starts a 3 2 1 countdown, then it explodes and comes back later.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local COUNTDOWN = 3 -- seconds before it explodes
local RESPAWN_TIME = 4 -- seconds before it comes back
local DAMAGE = 60

local platform = script.Parent
local active = false

-- Floating number above the platform
local billboard = Instance.new("BillboardGui")
billboard.Size = UDim2.fromOffset(80, 80)
billboard.StudsOffset = Vector3.new(0, 4, 0)
billboard.AlwaysOnTop = true
billboard.Parent = platform
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextScaled = true
label.Font = Enum.Font.FredokaOne
label.TextColor3 = Color3.fromRGB(255, 80, 60)
label.Text = ""
label.Parent = billboard

platform.Touched:Connect(function(hit)
	if active or not Players:GetPlayerFromCharacter(hit.Parent) then
		return
	end
	active = true
	for i = COUNTDOWN, 1, -1 do
		label.Text = tostring(i)
		task.wait(1)
	end
	label.Text = ""

	-- BOOM! DestroyJointRadiusPercent = 0 means it only hurts, it does not insta-kill
	local explosion = Instance.new("Explosion")
	explosion.Position = platform.Position
	explosion.BlastRadius = math.max(platform.Size.X, platform.Size.Z)
	explosion.DestroyJointRadiusPercent = 0
	local hurt = {}
	explosion.Hit:Connect(function(part)
		local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and not hurt[humanoid] then
			hurt[humanoid] = true
			humanoid:TakeDamage(DAMAGE)
		end
	end)
	explosion.Parent = workspace

	-- Disappear, then come back
	platform.Transparency = 1
	platform.CanCollide = false
	task.wait(RESPAWN_TIME)
	platform.Transparency = 0
	platform.CanCollide = true
	active = false
end)
