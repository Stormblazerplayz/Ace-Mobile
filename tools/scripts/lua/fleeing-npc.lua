-- @title NPC that runs away
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an NPC or animal Model with a Humanoid (like a chicken or a scared villager).
-- @keywords flee, run away npc, scared npc, chicken ai, escape from player
-- @about When a player gets close, the NPC runs in the opposite direction, then calms down when they are far away.

local Players = game:GetService("Players")

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")

-- Settings: change these!
local SCARED_DISTANCE = 20
local RUN_SPEED = 20
local CALM_SPEED = 6

root:SetNetworkOwner(nil)

local function closestThreat()
	local best, bestDistance = nil, SCARED_DISTANCE
	for _, player in ipairs(Players:GetPlayers()) do
		local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if theirRoot then
			local distance = (theirRoot.Position - root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = theirRoot, distance
			end
		end
	end
	return best
end

while humanoid.Health > 0 do
	local threat = closestThreat()
	if threat then
		humanoid.WalkSpeed = RUN_SPEED
		local away = (root.Position - threat.Position) * Vector3.new(1, 0, 1)
		if away.Magnitude < 0.1 then
			away = Vector3.new(1, 0, 0)
		end
		-- Run 15 studs further away, with a little zig-zag
		local zigzag = Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
		humanoid:MoveTo(root.Position + away.Unit * 15 + zigzag)
		task.wait(0.3)
	else
		humanoid.WalkSpeed = CALM_SPEED
		task.wait(1)
	end
end
