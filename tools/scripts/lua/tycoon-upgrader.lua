-- @title Tycoon upgrader
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside a non-colliding Part that hangs over your conveyor so drops pass through it.
-- @keywords tycoon upgrader, upgrade drops, multiply drop value, ore upgrader, double the money blocks
-- @about Money blocks that pass through the upgrader become worth more and change color.

-- Settings: change these!
local MULTIPLY = 2 -- 2 = worth double
local NEW_COLOR = Color3.fromRGB(80, 220, 255)

local upgrader = script.Parent
upgrader.CanCollide = false
upgrader.Transparency = 0.5

upgrader.Touched:Connect(function(hit)
	local value = hit:GetAttribute("Value")
	-- Only upgrade each block once at this upgrader
	if not value or hit:GetAttribute("Upgraded_" .. upgrader.Name) then
		return
	end
	hit:SetAttribute("Upgraded_" .. upgrader.Name, true)
	hit:SetAttribute("Value", value * MULTIPLY)
	hit.Color = NEW_COLOR
	hit.Material = Enum.Material.Neon
end)
