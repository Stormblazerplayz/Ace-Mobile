-- @title Group members only door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored door Part and put your Roblox group id below.
-- @keywords group door, group only, join the group to enter, group rank door, clan door
-- @about Only members of your Roblox group (with a high enough rank, if you want) can go through this door.

local Players = game:GetService("Players")

-- Settings: change these!
local GROUP_ID = 0
local MIN_RANK = 1 -- 1 = any member, 255 = only the owner

local door = script.Parent
door.Anchored = true
local allowed = {}
local cooldown = {}

local function isAllowed(player)
	if allowed[player] == nil then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(GROUP_ID)
		end)
		allowed[player] = ok and rank >= MIN_RANK
	end
	return allowed[player]
end

local function passThrough(root)
	local side = door.CFrame:PointToObjectSpace(root.Position).Z
	local distance = door.Size.Z / 2 + 3
	local target = door.CFrame * CFrame.new(0, 0, side > 0 and -distance or distance)
	root.Parent:PivotTo(CFrame.new(target.Position) * root.CFrame.Rotation)
end

door.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or cooldown[player] then
		return
	end
	cooldown[player] = true
	if isAllowed(player) then
		passThrough(root)
	else
		player:SetAttribute("Notice", "Join the group to get in!")
	end
	task.wait(1.5)
	cooldown[player] = nil
end)

Players.PlayerRemoving:Connect(function(player)
	allowed[player] = nil
	cooldown[player] = nil
end)
