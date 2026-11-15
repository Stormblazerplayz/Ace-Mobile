-- @title Glowing light pulse
-- @category World and effects
-- @kind Script
-- @where Put this Script inside a Part; it adds a PointLight if there is not one already.
-- @keywords glowing pulse, pulsing light, light breathes, magic glow, crystal glow, slow glow
-- @about Makes a soft light that slowly glows brighter and dimmer and shifts color, great for crystals and portals.

local TweenService = game:GetService("TweenService")

-- Settings: change these!
local COLOR_A = Color3.fromRGB(80, 160, 255)
local COLOR_B = Color3.fromRGB(200, 80, 255)
local MAX_BRIGHTNESS = 4
local PULSE_TIME = 1.5

local part = script.Parent
part.Material = Enum.Material.Neon
local light = part:FindFirstChildWhichIsA("PointLight") or Instance.new("PointLight")
light.Range = 16
light.Color = COLOR_A
light.Brightness = 0.5
light.Parent = part
part.Color = COLOR_A

-- Repeat forever (-1) and reverse back each time (true)
local info = TweenInfo.new(PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
TweenService:Create(light, info, { Brightness = MAX_BRIGHTNESS, Color = COLOR_B }):Play()
TweenService:Create(part, info, { Color = COLOR_B }):Play()
