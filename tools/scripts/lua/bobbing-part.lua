-- @title Floating bobbing part
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an Anchored Part (great for floating islands, gems or boats on water).
-- @keywords bobbing part, floating up and down, hovering gem, bob in the water, float animation
-- @about Makes the part float gently up and down and slowly turn, like it is hovering.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local BOB_HEIGHT = 1.5 -- studs up and down
local BOB_TIME = 2 -- seconds to go up once
local SPIN = true -- also turn slowly?

local part = script.Parent
part.Anchored = true
local start = part.CFrame

-- A tween that goes up, then reverses back down, forever (-1 means repeat forever)
local info = TweenInfo.new(BOB_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

if not SPIN then
	TweenService:Create(part, info, { CFrame = start + Vector3.new(0, BOB_HEIGHT, 0) }):Play()
	return
end

-- With spinning we work out the position ourselves every frame
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	local up = math.sin(t * math.pi / BOB_TIME) * BOB_HEIGHT / 2
	part.CFrame = start * CFrame.new(0, up, 0) * CFrame.Angles(0, t * 0.5, 0)
end)
