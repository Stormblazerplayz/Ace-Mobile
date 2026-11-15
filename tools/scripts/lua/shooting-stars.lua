-- @title Shooting stars at night
-- @category World and effects
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords shooting stars, falling stars, night sky streaks, make a wish, star trails
-- @about At night, glowing shooting stars streak across the sky every few seconds.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local MIN_WAIT, MAX_WAIT = 3, 10 -- seconds between stars
local HEIGHT = 400

local function isNight()
	return Lighting.ClockTime >= 19 or Lighting.ClockTime < 5
end

local function shootStar()
	local camera = workspace.CurrentCamera.CFrame.Position
	local start = camera + Vector3.new(math.random(-600, 600), HEIGHT, math.random(-600, 600))
	local finish = start + Vector3.new(math.random(-300, 300), -120, math.random(-300, 300))

	local star = Instance.new("Part")
	star.Size = Vector3.new(1.5, 1.5, 1.5)
	star.Shape = Enum.PartType.Ball
	star.Material = Enum.Material.Neon
	star.Color = Color3.fromRGB(255, 255, 230)
	star.Anchored = true
	star.CanCollide = false
	star.CanQuery = false
	star.CanTouch = false
	star.Position = start
	-- A trail makes the glowing tail
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.7, 0)
	a0.Parent = star
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.7, 0)
	a1.Parent = star
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.6
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Transparency = NumberSequence.new(0, 1)
	trail.Parent = star
	star.Parent = workspace

	local fly = TweenService:Create(star, TweenInfo.new(1.2, Enum.EasingStyle.Linear), { Position = finish, Transparency = 1 })
	fly:Play()
	Debris:AddItem(star, 2)
end

while true do
	task.wait(math.random(MIN_WAIT, MAX_WAIT))
	if isNight() then
		shootStar()
	end
end
