-- @title Crusher that slams down
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored Part placed in the air above the path (the crusher block).
-- @keywords crusher, piston trap, slamming block, smash trap, ceiling crusher
-- @about The block slams down fast, crushing anyone under it, then slowly rises back up.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local DROP_DISTANCE = 10 -- how far down it slams (studs)
local WAIT_UP = 2 -- seconds it waits at the top
local WAIT_DOWN = 0.5 -- seconds it stays down

local crusher = script.Parent
crusher.Anchored = true
local top = crusher.CFrame
local bottom = top * CFrame.new(0, -DROP_DISTANCE, 0)

local slam = TweenService:Create(crusher, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = bottom })
local rise = TweenService:Create(crusher, TweenInfo.new(1.5, Enum.EasingStyle.Sine), { CFrame = top })

local slamming = false
crusher.Touched:Connect(function(hit)
	if not slamming then
		return -- it is only deadly while falling
	end
	local character = hit.Parent
	if Players:GetPlayerFromCharacter(character) then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
end)

while true do
	task.wait(WAIT_UP)
	slamming = true
	slam:Play()
	slam.Completed:Wait()
	slamming = false
	task.wait(WAIT_DOWN)
	rise:Play()
	rise.Completed:Wait()
end
