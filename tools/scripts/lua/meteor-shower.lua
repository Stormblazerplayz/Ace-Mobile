-- @title Meteor shower
-- @category World and effects
-- @kind Script
-- @where Put this Script inside a big flat, invisible, non-colliding Anchored Part high in the sky above where meteors should land.
-- @keywords meteor shower, falling meteors, asteroids fall, fire rocks from the sky, meteor strike
-- @about Flaming meteors fall from the sky at random spots and explode when they hit the ground.

local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local METEOR_EVERY = 2 -- seconds between meteors
local SIZE = 4
local FALL_SPEED = 120

local sky = script.Parent
sky.Transparency = 1
sky.CanCollide = false
sky.CanTouch = false

local function dropMeteor()
	local x = (math.random() - 0.5) * sky.Size.X
	local z = (math.random() - 0.5) * sky.Size.Z
	local meteor = Instance.new("Part")
	meteor.Shape = Enum.PartType.Ball
	meteor.Size = Vector3.new(SIZE, SIZE, SIZE)
	meteor.Material = Enum.Material.Basalt
	meteor.Color = Color3.fromRGB(80, 40, 30)
	meteor.CFrame = sky.CFrame * CFrame.new(x, 0, z)
	local fire = Instance.new("Fire")
	fire.Size = SIZE * 2
	fire.Heat = 20
	fire.Parent = meteor
	meteor.Parent = workspace
	meteor:SetNetworkOwner(nil)
	-- Falls at an angle so it looks cool
	meteor.AssemblyLinearVelocity = Vector3.new(math.random(-20, 20), -FALL_SPEED, math.random(-20, 20))

	local landed = false
	meteor.Touched:Connect(function(hit)
		if landed or hit:IsDescendantOf(meteor) then
			return
		end
		landed = true
		local boom = Instance.new("Explosion")
		boom.Position = meteor.Position
		boom.BlastRadius = SIZE * 2
		boom.DestroyJointRadiusPercent = 0.3
		boom.Parent = workspace
		meteor:Destroy()
	end)
	Debris:AddItem(meteor, 10)
end

while true do
	dropMeteor()
	task.wait(METEOR_EVERY)
end
