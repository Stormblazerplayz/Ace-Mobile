-- @title Trap door floor
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored Part that is the trap door in the floor.
-- @keywords trap door, floor opens, drop through floor, trapdoor, secret pit
-- @about Every few seconds the trap door swings open and drops anyone standing on it, then closes again.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local CLOSED_TIME = 4 -- seconds it stays shut
local OPEN_TIME = 2 -- seconds it stays open

local door = script.Parent
door.Anchored = true
local closed = door.CFrame
-- Swing down 90 degrees around one edge (the edge on the -X side)
local hinge = closed * CFrame.new(-door.Size.X / 2, 0, 0)
local open = hinge * CFrame.Angles(0, 0, math.rad(-90)) * CFrame.new(door.Size.X / 2, 0, 0)

local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
local openTween = TweenService:Create(door, info, { CFrame = open })
local closeTween = TweenService:Create(door, TweenInfo.new(0.8), { CFrame = closed })

while true do
	task.wait(CLOSED_TIME)
	door.CanCollide = false -- players fall right through
	openTween:Play()
	task.wait(OPEN_TIME)
	closeTween:Play()
	closeTween.Completed:Wait()
	door.CanCollide = true
end
