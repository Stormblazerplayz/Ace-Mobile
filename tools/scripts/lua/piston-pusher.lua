-- @title Piston that pushes players
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an Anchored Part placed beside the path, with its front face pointing at the path.
-- @keywords piston pusher, push players off, punching wall, side pusher, knock off platform
-- @about The piston shoots out, shoves any player it hits off the path, then pulls back in.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local PUSH_DISTANCE = 8 -- how far it shoots out
local PUSH_FORCE = 80 -- how hard players fly
local WAIT_TIME = 2 -- seconds between pushes

local piston = script.Parent
piston.Anchored = true
local inCFrame = piston.CFrame
local outCFrame = inCFrame * CFrame.new(0, 0, -PUSH_DISTANCE) -- "forward" is minus Z

local shootOut = TweenService:Create(piston, TweenInfo.new(0.15), { CFrame = outCFrame })
local pullIn = TweenService:Create(piston, TweenInfo.new(1), { CFrame = inCFrame })
local pushing = false
local pushed = {}

piston.Touched:Connect(function(hit)
	if not pushing then
		return
	end
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if player and root and not pushed[player] then
		pushed[player] = true
		root.AssemblyLinearVelocity = inCFrame.LookVector * PUSH_FORCE + Vector3.new(0, 20, 0)
	end
end)

while true do
	task.wait(WAIT_TIME)
	table.clear(pushed)
	pushing = true
	shootOut:Play()
	shootOut.Completed:Wait()
	pushing = false
	pullIn:Play()
	pullIn.Completed:Wait()
end
