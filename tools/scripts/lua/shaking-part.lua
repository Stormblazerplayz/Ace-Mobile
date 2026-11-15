-- @title Shaking part
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an Anchored Part (or the PrimaryPart of a Model) that should rattle.
-- @keywords shaking part, rattle, vibrating part, wobble, jiggle, trembling block
-- @about Makes the part rattle and shake in place, great for engines, washing machines or scary things.

local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local SHAKE_AMOUNT = 0.15 -- studs it moves each way
local TILT_AMOUNT = 2 -- degrees it tilts
local ONLY_SOMETIMES = false -- true = shake for 1 second every few seconds

local part = script.Parent
part.Anchored = true
local home = part.CFrame
local shaking = true

local function random(amount)
	return (math.random() * 2 - 1) * amount
end

RunService.Heartbeat:Connect(function()
	if not shaking then
		part.CFrame = home
		return
	end
	part.CFrame = home
		* CFrame.new(random(SHAKE_AMOUNT), random(SHAKE_AMOUNT), random(SHAKE_AMOUNT))
		* CFrame.Angles(math.rad(random(TILT_AMOUNT)), 0, math.rad(random(TILT_AMOUNT)))
end)

if ONLY_SOMETIMES then
	while true do
		shaking = false
		task.wait(math.random(3, 6))
		shaking = true
		task.wait(1)
	end
end
