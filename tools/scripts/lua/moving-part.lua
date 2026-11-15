-- @title Moving platform
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside the Part you want to slide back and forth (it will be Anchored for you).
-- @keywords moving platform, moving part, part that goes back and forth, sliding part, moving block, platform that moves
-- @about Slides the part back and forth forever, and players standing on it ride along.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local MOVE_BY = Vector3.new(0, 0, 20) -- how far it moves (X, Y, Z in studs)
local TIME = 3 -- seconds to move one way (smaller = faster)

local part = script.Parent
part.Anchored = true
local startPosition = part.Position

-- Slide to the end, then back again, forever (-1 = repeat forever, true = go back)
local info = TweenInfo.new(TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local tween = TweenService:Create(part, info, { Position = startPosition + MOVE_BY })
tween:Play()

-- This tells physics how fast the part moves, so players on top ride along
local lastPosition = part.Position
RunService.Heartbeat:Connect(function(dt)
	local nowPosition = part.Position
	if dt > 0 then
		part.AssemblyLinearVelocity = (nowPosition - lastPosition) / dt
	end
	lastPosition = nowPosition
end)
