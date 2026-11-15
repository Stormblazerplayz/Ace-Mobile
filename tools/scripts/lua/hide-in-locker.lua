-- @title Hide in a locker
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside a locker Model with a Part named Inside (an invisible, non-colliding part in the middle of the locker) and a Part named LockerDoor.
-- @keywords hide in locker, hiding spot, hide from monster, closet hide, hide and seek locker
-- @about Press E to hide inside the locker (you cannot move and you get a Hiding attribute), and press E again to come out.

-- Settings: change this!
local EXIT_DISTANCE = 4 -- studs in front of the locker you pop out

local locker = script.Parent
local inside = locker:WaitForChild("Inside")
local lockerDoor = locker:WaitForChild("LockerDoor")
local hider = nil -- the player hiding right now
local saved = {}

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Hide"
prompt.ObjectText = "Locker"
prompt.RequiresLineOfSight = false
prompt.Parent = lockerDoor

prompt.Triggered:Connect(function(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if hider == nil then
		-- Go in: freeze the player inside the locker
		hider = player
		saved = { humanoid.WalkSpeed, humanoid.JumpHeight }
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		character:PivotTo(inside.CFrame)
		player:SetAttribute("Hiding", true) -- monsters can check this and ignore them
		prompt.ActionText = "Leave"
		humanoid.Died:Once(function()
			if hider == player then
				hider = nil
				player:SetAttribute("Hiding", nil)
				prompt.ActionText = "Hide"
			end
		end)
	elseif hider == player then
		-- Come out in front of the locker door
		hider = nil
		humanoid.WalkSpeed = saved[1]
		humanoid.JumpHeight = saved[2]
		character:PivotTo(lockerDoor.CFrame * CFrame.new(0, 0, -EXIT_DISTANCE))
		player:SetAttribute("Hiding", nil)
		prompt.ActionText = "Hide"
	end
end)

-- If the hider leaves the game or dies, free up the locker
game:GetService("Players").PlayerRemoving:Connect(function(player)
	if player == hider then
		hider = nil
		prompt.ActionText = "Hide"
	end
end)
