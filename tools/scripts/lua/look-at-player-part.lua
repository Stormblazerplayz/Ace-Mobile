-- @title Part that watches the nearest player
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an Anchored Part (like an eyeball, statue head or camera) whose front face should look at players.
-- @keywords look at player, eyeball follows you, watching statue, turn to face player, creepy eye
-- @about Turns the part every frame so its front face looks at the closest player.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local RANGE = 60 -- only watch players closer than this
local TURN_SPEED = 8 -- bigger = snaps faster, smaller = turns lazily

local part = script.Parent
part.Anchored = true
local restCFrame = part.CFrame

local function nearestRoot()
	local best, bestDistance = nil, RANGE
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local distance = (root.Position - part.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = root, distance
			end
		end
	end
	return best
end

RunService.Heartbeat:Connect(function(deltaTime)
	local target = nearestRoot()
	local goal = restCFrame
	if target then
		goal = CFrame.lookAt(part.Position, target.Position)
	end
	-- Lerp turns a little bit toward the goal each frame, so it looks smooth
	part.CFrame = part.CFrame:Lerp(goal, math.clamp(TURN_SPEED * deltaTime, 0, 1))
end)
