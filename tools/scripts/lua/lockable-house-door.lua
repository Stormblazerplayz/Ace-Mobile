-- @title House door the owner can lock
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored front door Part of a house.
-- @keywords lock door, claim a house, owner locks door, my house door, lock and unlock
-- @about The first player to claim the house becomes the owner and can lock the door so nobody else can open it.

local Players = game:GetService("Players")

local door = script.Parent
door.Anchored = true
local owner = nil
local locked = false
local isOpen = false

local openPrompt = Instance.new("ProximityPrompt")
openPrompt.ActionText = "Open"
openPrompt.ObjectText = "Door"
openPrompt.Parent = door

local lockPrompt = Instance.new("ProximityPrompt")
lockPrompt.ActionText = "Claim house"
lockPrompt.ObjectText = "House"
lockPrompt.KeyboardKeyCode = Enum.KeyCode.F -- a different key than the door
lockPrompt.UIOffset = Vector2.new(0, 80) -- show below the other prompt
lockPrompt.Parent = door

local function setOpen(open)
	isOpen = open
	door.Transparency = open and 0.7 or 0
	door.CanCollide = not open
	openPrompt.ActionText = open and "Close" or "Open"
end

openPrompt.Triggered:Connect(function(player)
	if locked and player ~= owner then
		player:SetAttribute("Notice", "The door is locked!")
		return
	end
	setOpen(not isOpen)
end)

lockPrompt.Triggered:Connect(function(player)
	if owner == nil then
		owner = player
		lockPrompt.ObjectText = player.DisplayName .. "'s House"
		lockPrompt.ActionText = "Lock"
	elseif player == owner then
		locked = not locked
		lockPrompt.ActionText = locked and "Unlock" or "Lock"
		if locked then
			setOpen(false)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if player == owner then
		owner = nil
		locked = false
		lockPrompt.ObjectText = "House"
		lockPrompt.ActionText = "Claim house"
	end
end)
