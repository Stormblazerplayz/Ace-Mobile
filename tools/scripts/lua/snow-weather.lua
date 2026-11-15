-- @title Snow
-- @category World and effects
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords snow, snowfall, snowy weather, snowflakes, winter weather, let it snow
-- @about Soft snowflakes drift down around the player; it can always snow, or only when the Weather attribute on Workspace is Snow.

local RunService = game:GetService("RunService")

-- Settings: change these!
local ALWAYS_SNOW = false -- false = only when workspace's "Weather" attribute is "Snow"
local FLAKES_PER_SECOND = 200

local camera = workspace.CurrentCamera

local cloud = Instance.new("Part")
cloud.Name = "SnowCloud"
cloud.Size = Vector3.new(100, 1, 100)
cloud.Transparency = 1
cloud.Anchored = true
cloud.CanCollide = false
cloud.CanQuery = false
cloud.CanTouch = false
cloud.Parent = workspace

local snow = Instance.new("ParticleEmitter")
snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
snow.Size = NumberSequence.new(0.25)
snow.Speed = NumberRange.new(6, 10) -- slow and floaty
snow.Lifetime = NumberRange.new(6, 8)
snow.SpreadAngle = Vector2.new(15, 15)
snow.RotSpeed = NumberRange.new(-60, 60)
snow.Acceleration = Vector3.new(1, 0, 0.5) -- a gentle breeze
snow.EmissionDirection = Enum.NormalId.Bottom
snow.Rate = FLAKES_PER_SECOND
snow.Parent = cloud

RunService.RenderStepped:Connect(function()
	cloud.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 35, 0))
	snow.Enabled = ALWAYS_SNOW or workspace:GetAttribute("Weather") == "Snow"
end)
