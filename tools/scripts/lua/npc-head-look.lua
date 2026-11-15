-- @title NPC head turns to look at you
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an R15 NPC Model (made with the Rig Builder). It needs Head with a Motor6D named Neck.
-- @keywords head look, npc looks at player, head tracking, eye contact npc, turn head
-- @about The NPC's head smoothly turns to watch the nearest player who walks by, then looks forward again.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local npc = script.Parent
local head = npc:WaitForChild("Head")
local neck = head:WaitForChild("Neck") -- R15 rigs keep the Neck in the Head

-- Settings: change these!
local LOOK_RANGE = 25
local MAX_TURN = math.rad(70) -- how far the head can turn left or right

local startC0 = neck.C0

local function nearestHead()
	local best, bestDistance = nil, LOOK_RANGE
	for _, player in ipairs(Players:GetPlayers()) do
		local theirHead = player.Character and player.Character:FindFirstChild("Head")
		if theirHead then
			local distance = (theirHead.Position - head.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = theirHead, distance
			end
		end
	end
	return best
end

RunService.Heartbeat:Connect(function()
	local target = nearestHead()
	local goal = startC0
	if target then
		-- Work out the direction from the body's point of view
		local body = neck.Part0
		local direction = body.CFrame:PointToObjectSpace(target.Position)
		local yaw = math.clamp(math.atan2(-direction.X, -direction.Z), -MAX_TURN, MAX_TURN)
		local pitch = math.clamp(math.atan2(direction.Y - 1.5, math.sqrt(direction.X ^ 2 + direction.Z ^ 2)), -0.5, 0.5)
		goal = startC0 * CFrame.Angles(pitch, yaw, 0)
	end
	neck.C0 = neck.C0:Lerp(goal, 0.15) -- move a bit each frame for smooth turning
end)
