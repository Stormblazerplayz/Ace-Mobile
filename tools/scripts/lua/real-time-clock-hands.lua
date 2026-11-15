-- @title Clock with moving hands
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside a Model with an Anchored Part named Center (its front face is the clock face) and Anchored Parts named HourHand, MinuteHand and SecondHand (each long along Y).
-- @keywords clock hands, working clock, wall clock, real time clock, tick tock clock
-- @about Turns the clock hands to show the real time of day, ticking every second.

-- Settings: change this to your time zone! (hours away from UTC, like -5 for New York, 1 for Paris)
local TIME_ZONE = -5

local model = script.Parent
local center = model:WaitForChild("Center")
local hands = {
	{ part = model:WaitForChild("HourHand"), depth = 0.2 },
	{ part = model:WaitForChild("MinuteHand"), depth = 0.3 },
	{ part = model:WaitForChild("SecondHand"), depth = 0.4 },
}

-- Point a hand at an angle (0 = 12 o'clock) with one end at the middle of the clock
local function placeHand(hand, fraction)
	local angle = fraction * math.pi * 2
	local part = hand.part
	part.Anchored = true
	part.CFrame = center.CFrame
		* CFrame.new(0, 0, -hand.depth) -- sit a bit in front of the face so you can see it
		* CFrame.Angles(0, 0, angle) -- turn clockwise
		* CFrame.new(0, part.Size.Y / 2, 0) -- move out so the end sits in the middle
end

while true do
	local now = os.date("!*t", os.time() + TIME_ZONE * 3600)
	local seconds = now.sec
	local minutes = now.min + seconds / 60
	local hours = (now.hour % 12) + minutes / 60
	placeHand(hands[1], hours / 12)
	placeHand(hands[2], minutes / 60)
	placeHand(hands[3], seconds / 60)
	task.wait(1)
end
