-- @title Part that grows and shrinks
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an Anchored Part.
-- @keywords grow and shrink, pulsing part, breathing part, heartbeat pulse, size tween
-- @about Makes the part smoothly grow bigger and shrink back forever, like it is breathing.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local GROW_AMOUNT = 1.5 -- 1.5 = grows to one and a half times as big
local PULSE_TIME = 1 -- seconds to grow once
local GLOW = true -- also get brighter when big?

local part = script.Parent
part.Anchored = true
local goal = { Size = part.Size * GROW_AMOUNT }
if GLOW then
	goal.Transparency = math.max(part.Transparency - 0.3, 0)
	part.Transparency = math.min(part.Transparency + 0.3, 0.9)
end

-- RepeatCount -1 = forever, Reverses true = shrink back after growing
local info = TweenInfo.new(PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
TweenService:Create(part, info, goal):Play()
