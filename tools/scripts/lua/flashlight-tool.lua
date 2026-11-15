-- @title Flashlight
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part (the flashlight, pointing forward) and put the Tool in StarterPack.
-- @keywords flashlight, torch light, spotlight tool, light in the dark, horror flashlight
-- @about Click to switch the flashlight on and off; everyone can see the beam.

-- Settings: change these numbers!
local BRIGHTNESS = 3
local RANGE = 60
local ANGLE = 45 -- how wide the beam is

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

local light = Instance.new("SpotLight")
light.Brightness = BRIGHTNESS
light.Range = RANGE
light.Angle = ANGLE
light.Face = Enum.NormalId.Front -- shine out of the front of the handle
light.Shadows = true
light.Enabled = false
light.Parent = handle

-- Activated runs on the server, so the light changes for everyone
tool.Activated:Connect(function()
	light.Enabled = not light.Enabled
	handle.Material = light.Enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic
end)

-- Switch it off when put away
tool.Unequipped:Connect(function()
	light.Enabled = false
	handle.Material = Enum.Material.SmoothPlastic
end)
