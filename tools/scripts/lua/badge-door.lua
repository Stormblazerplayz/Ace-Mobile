-- @title Badge door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored door Part and put your badge id below.
-- @keywords badge door, need a badge to enter, badge required, door for badge owners, unlock with badge
-- @about Only players who own a certain badge can go through this door, so you can lock areas until a badge is earned.

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

-- Settings: change this!
local BADGE_ID = 0

local door = script.Parent
door.Anchored = true
local hasBadge = {}
local cooldown = {}

local function checkBadge(player)
	if not hasBadge[player] then
		local ok, owns = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, BADGE_ID)
		end)
		hasBadge[player] = ok and owns -- once true it stays true
	end
	return hasBadge[player]
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
	if checkBadge(player) then
		passThrough(root)
	else
		player:SetAttribute("Notice", "You need the badge to enter!")
	end
	task.wait(2)
	cooldown[player] = nil
end)

Players.PlayerRemoving:Connect(function(player)
	hasBadge[player] = nil
	cooldown[player] = nil
end)
