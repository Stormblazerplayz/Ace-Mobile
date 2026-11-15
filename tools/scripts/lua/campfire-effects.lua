-- @title Campfire
-- @category World and effects
-- @kind Script
-- @where Put this Script inside an Anchored Part in the middle of your log pile.
-- @keywords campfire, fire effect, cozy fire, smoke and flames, flickering fire light
-- @about Adds flames, rising smoke, flying embers and a warm flickering light to make a cozy campfire.

-- Settings: change these!
local FIRE_SIZE = 6
local LIGHT_RANGE = 20

local base = script.Parent
base.Transparency = 1
base.CanCollide = false

local fire = Instance.new("Fire")
fire.Size = FIRE_SIZE
fire.Heat = 12
fire.Color = Color3.fromRGB(255, 140, 40)
fire.SecondaryColor = Color3.fromRGB(255, 60, 20)
fire.Parent = base

local smoke = Instance.new("Smoke")
smoke.Color = Color3.fromRGB(90, 90, 90)
smoke.Opacity = 0.1
smoke.RiseVelocity = 4
smoke.Size = 3
smoke.Parent = base

-- Little glowing embers that float up
local embers = Instance.new("ParticleEmitter")
embers.Color = ColorSequence.new(Color3.fromRGB(255, 160, 60))
embers.LightEmission = 1
embers.Size = NumberSequence.new(0.15, 0)
embers.Speed = NumberRange.new(3, 6)
embers.Lifetime = NumberRange.new(1.5, 2.5)
embers.SpreadAngle = Vector2.new(25, 25)
embers.Acceleration = Vector3.new(0, 2, 0)
embers.Rate = 8
embers.EmissionDirection = Enum.NormalId.Top
embers.Parent = base

local light = Instance.new("PointLight")
light.Color = Color3.fromRGB(255, 150, 70)
light.Range = LIGHT_RANGE
light.Shadows = true
light.Parent = base

-- Flicker the light gently
while true do
	light.Brightness = 1.5 + math.random() * 1
	light.Range = LIGHT_RANGE + math.random(-2, 2)
	task.wait(0.08 + math.random() * 0.12)
end
