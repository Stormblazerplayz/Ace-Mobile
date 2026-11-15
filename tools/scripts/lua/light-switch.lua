-- @title Light switch
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside a Model with a Part named Switch and a Folder named Lights holding lamp Parts that have a PointLight, SpotLight or SurfaceLight inside.
-- @keywords light switch, turn lights on and off, lamp switch, room lights, flip the lights
-- @about Click the switch to turn all the room's lights on or off; lamp parts glow when on.

-- Settings: change these!
local ON_MATERIAL = Enum.Material.Neon
local OFF_MATERIAL = Enum.Material.SmoothPlastic

local model = script.Parent
local switch = model:WaitForChild("Switch")
local lights = model:WaitForChild("Lights")

local clicker = Instance.new("ClickDetector")
clicker.MaxActivationDistance = 12
clicker.Parent = switch

local on = true

local function apply()
	for _, thing in ipairs(lights:GetDescendants()) do
		if thing:IsA("Light") then -- PointLight, SpotLight and SurfaceLight are all Lights
			thing.Enabled = on
		elseif thing:IsA("BasePart") then
			thing.Material = on and ON_MATERIAL or OFF_MATERIAL
		end
	end
	switch.Color = on and Color3.fromRGB(255, 240, 150) or Color3.fromRGB(80, 80, 80)
end

clicker.MouseClick:Connect(function()
	on = not on
	apply()
end)
apply()
