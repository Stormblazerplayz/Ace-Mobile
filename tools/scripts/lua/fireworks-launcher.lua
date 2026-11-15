-- @title Fireworks launcher
-- @category World and effects
-- @kind Script
-- @where Put this Script inside an Anchored Part on the ground (the launcher).
-- @keywords fireworks, firework show, launch fireworks, rocket fireworks, celebration fireworks
-- @about Click the launcher to shoot a firework into the sky that bursts into colorful sparks.

local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local HEIGHT = 80 -- how high the firework goes
local FLIGHT_TIME = 1.2
local SPARKS = 120

local launcher = script.Parent
local clicker = Instance.new("ClickDetector")
clicker.Parent = launcher

local function launch()
	local color = Color3.fromHSV(math.random(), 0.8, 1)
	local rocket = Instance.new("Part")
	rocket.Size = Vector3.new(0.5, 1.5, 0.5)
	rocket.Anchored = true
	rocket.CanCollide = false
	rocket.Material = Enum.Material.Neon
	rocket.Color = color
	rocket.Position = launcher.Position + Vector3.new(0, launcher.Size.Y, 0)
	rocket.Parent = workspace

	-- Sparks that burst out at the top
	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(color)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(0.6, 0)
	sparks.Speed = NumberRange.new(30, 45)
	sparks.Lifetime = NumberRange.new(1, 1.6)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Drag = 2
	sparks.Acceleration = Vector3.new(0, -15, 0)
	sparks.Rate = 0 -- we Emit them all at once
	sparks.Parent = rocket

	-- Fly up
	local start = rocket.Position
	local t0 = os.clock()
	while os.clock() - t0 < FLIGHT_TIME do
		local alpha = (os.clock() - t0) / FLIGHT_TIME
		rocket.Position = start + Vector3.new(math.sin(alpha * 10) * 0.5, HEIGHT * alpha, 0)
		task.wait()
	end
	rocket.Transparency = 1
	sparks:Emit(SPARKS)
	Debris:AddItem(rocket, 3)
end

local busy = false
clicker.MouseClick:Connect(function()
	if busy then
		return
	end
	busy = true
	task.spawn(launch)
	task.wait(0.5)
	busy = false
end)
