-- @title Admin only door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored door Part and put admin user ids in the list.
-- @keywords admin door, owner only door, staff room door, developer room, only admins can enter
-- @about Only the user ids in your admin list can walk through this door; everyone else bumps into it.

local Players = game:GetService("Players")

-- Settings: put the user ids of your admins here
local ADMINS = {
	[1] = true, -- change 1 to your user id
}

local door = script.Parent
door.Anchored = true
door.CanCollide = true
local cooldown = {}

-- Put the player on the other side of the door
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
	if not player or not root or cooldown[player] or not ADMINS[player.UserId] then
		return
	end
	cooldown[player] = true
	passThrough(root)
	task.wait(1)
	cooldown[player] = nil
end)
