-- @title Rainbow part
-- @category World and effects
-- @kind Script
-- @where Put this Script inside a Part (or inside a Model to make every part in it rainbow).
-- @keywords rainbow part, color changing part, rainbow colors, disco floor, part that changes color
-- @about Smoothly changes the color through the whole rainbow, over and over.

-- Settings: change these numbers!
local SPEED = 0.2 -- how fast the colors change (1 = whole rainbow every second)
local SATURATION = 1 -- 0 = grey, 1 = super colorful
local BRIGHTNESS = 1 -- 0 = black, 1 = bright

local target = script.Parent
local hue = 0

-- Color the part, or every part inside the model
local function paint(color)
	if target:IsA("BasePart") then
		target.Color = color
	end
	for _, item in ipairs(target:GetDescendants()) do
		if item:IsA("BasePart") then
			item.Color = color
		end
	end
end

while true do
	local dt = task.wait(0.05)
	hue = (hue + SPEED * dt) % 1
	paint(Color3.fromHSV(hue, SATURATION, BRIGHTNESS))
end
