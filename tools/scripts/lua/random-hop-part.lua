-- @title Part that hops to random spots
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an Anchored Part, and make a Folder named HopSpots in Workspace with invisible Parts marking where it can appear.
-- @keywords random teleport part, hopping part, appears in random places, whack a mole part, part jumps around
-- @about Every few seconds the part fades out and pops up at a different random spot.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local STAY_TIME = 3 -- seconds it stays in one spot
local FADE_TIME = 0.3

local part = script.Parent
part.Anchored = true
local spots = workspace:WaitForChild("HopSpots")
local normalTransparency = part.Transparency
local lastSpot

local fadeOut = TweenService:Create(part, TweenInfo.new(FADE_TIME), { Transparency = 1 })
local fadeIn = TweenService:Create(part, TweenInfo.new(FADE_TIME), { Transparency = normalTransparency })

while true do
	task.wait(STAY_TIME)
	local choices = {}
	for _, spot in ipairs(spots:GetChildren()) do
		if spot:IsA("BasePart") and spot ~= lastSpot then
			table.insert(choices, spot)
		end
	end
	if #choices > 0 then
		local spot = choices[math.random(#choices)]
		lastSpot = spot
		fadeOut:Play()
		fadeOut.Completed:Wait()
		part.CFrame = spot.CFrame
		fadeIn:Play()
	end
end
