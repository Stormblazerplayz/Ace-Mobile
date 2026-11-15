-- @title Random lightning strikes
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside a big flat Anchored Part (your arena floor).
-- @keywords lightning strikes, random strikes, warning circle, dodge the lightning, zap from the sky
-- @about A red warning circle appears on the floor, then lightning strikes there and hurts anyone inside.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local STRIKE_EVERY = 1.5 -- seconds between strikes
local WARNING_TIME = 1.2 -- seconds you get to run away
local RADIUS = 6 -- size of the strike
local DAMAGE = 45

local floor = script.Parent

local function strike()
	-- Pick a random spot on top of the floor
	local x = (math.random() - 0.5) * floor.Size.X
	local z = (math.random() - 0.5) * floor.Size.Z
	local spot = (floor.CFrame * CFrame.new(x, floor.Size.Y / 2, z)).Position

	-- A flat red circle warns players
	local circle = Instance.new("Part")
	circle.Shape = Enum.PartType.Cylinder
	circle.Size = Vector3.new(0.2, RADIUS * 2, RADIUS * 2)
	circle.CFrame = CFrame.new(spot) * CFrame.Angles(0, 0, math.rad(90))
	circle.Anchored = true
	circle.CanCollide = false
	circle.Material = Enum.Material.Neon
	circle.Color = Color3.fromRGB(255, 50, 50)
	circle.Transparency = 0.5
	circle.Parent = workspace
	task.wait(WARNING_TIME)
	circle:Destroy()

	-- The bolt: a tall glowing beam from the sky
	local bolt = Instance.new("Part")
	bolt.Size = Vector3.new(1.5, 200, 1.5)
	bolt.CFrame = CFrame.new(spot + Vector3.new(0, 100, 0))
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.Material = Enum.Material.Neon
	bolt.Color = Color3.fromRGB(200, 230, 255)
	bolt.Parent = workspace
	Debris:AddItem(bolt, 0.25)

	-- Hurt everyone inside the circle
	local hurt = {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(spot, RADIUS)) do
		local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and not hurt[humanoid] and Players:GetPlayerFromCharacter(humanoid.Parent) then
			hurt[humanoid] = true
			humanoid:TakeDamage(DAMAGE)
		end
	end
end

while true do
	task.spawn(strike)
	task.wait(STRIKE_EVERY)
end
