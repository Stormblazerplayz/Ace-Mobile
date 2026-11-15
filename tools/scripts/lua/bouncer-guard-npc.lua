-- @title Bouncer guard NPC
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an NPC Model standing in front of an entrance. Set ALLOWED_TEAM, or give players a VIP attribute.
-- @keywords bouncer, guard npc, blocks entrance, vip guard, push players back
-- @about The guard pushes back any player who comes too close unless they are on the allowed team or have the VIP attribute.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these!
local GUARD_RANGE = 8
local ALLOWED_TEAM = "" -- team name that may pass ("" = nobody by team)
local PUSH_POWER = 60

local npc = script.Parent
local root = npc:WaitForChild("HumanoidRootPart")
local head = npc:FindFirstChild("Head") or root

local lastWarned = {}

local function warnPlayer(player)
	if os.clock() - (lastWarned[player] or 0) < 3 then
		return
	end
	lastWarned[player] = os.clock()
	local bubble = Instance.new("BillboardGui")
	bubble.Size = UDim2.fromOffset(200, 40)
	bubble.StudsOffset = Vector3.new(0, 3, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Text = "VIPs only, " .. player.DisplayName .. "!"
	label.Parent = bubble
	bubble.Parent = head
	Debris:AddItem(bubble, 2)
end

local function allowed(player)
	if player:GetAttribute("VIP") or player:GetAttribute("Premium") then
		return true
	end
	return ALLOWED_TEAM ~= "" and player.Team ~= nil and player.Team.Name == ALLOWED_TEAM
end

while true do
	task.wait(0.15)
	for _, player in ipairs(Players:GetPlayers()) do
		local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if theirRoot and not allowed(player) then
			local offset = (theirRoot.Position - root.Position) * Vector3.new(1, 0, 1)
			if offset.Magnitude < GUARD_RANGE and offset.Magnitude > 0 then
				-- Shove them away from the guard
				theirRoot.AssemblyLinearVelocity = offset.Unit * PUSH_POWER + Vector3.new(0, 20, 0)
				warnPlayer(player)
			end
		end
	end
end
