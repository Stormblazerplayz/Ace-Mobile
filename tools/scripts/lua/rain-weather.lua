-- @title Rain
-- @category World and effects
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords rain, rain effect, rainy weather, raindrops, make it rain
-- @about Makes rain fall all around the player's camera; it can always rain, or only when the Weather attribute on Workspace is Rain.

local RunService = game:GetService("RunService")

-- Settings: change these!
local ALWAYS_RAIN = false -- false = only when workspace's "Weather" attribute is "Rain" or "Storm"
local DROPS_PER_SECOND = 600

local camera = workspace.CurrentCamera

-- An invisible box high above the camera that the rain falls out of
local cloud = Instance.new("Part")
cloud.Name = "RainCloud"
cloud.Size = Vector3.new(120, 1, 120)
cloud.Transparency = 1
cloud.Anchored = true
cloud.CanCollide = false
cloud.CanQuery = false
cloud.CanTouch = false
cloud.Parent = workspace

local rain = Instance.new("ParticleEmitter")
rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
rain.Color = ColorSequence.new(Color3.fromRGB(180, 200, 255))
rain.Transparency = NumberSequence.new(0.3)
rain.Size = NumberSequence.new(0.15)
rain.Speed = NumberRange.new(80, 100)
rain.Lifetime = NumberRange.new(0.8, 1)
rain.EmissionDirection = Enum.NormalId.Bottom
rain.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
rain.Squash = NumberSequence.new(3) -- stretch dots into long raindrops
rain.Rate = DROPS_PER_SECOND
rain.Parent = cloud

RunService.RenderStepped:Connect(function()
	cloud.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 40, 0))
	local weather = workspace:GetAttribute("Weather")
	rain.Enabled = ALWAYS_RAIN or weather == "Rain" or weather == "Storm"
end)
