-- @title Door that opens when touched
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the door Part (make it Anchored).
-- @keywords door, door that opens, touch door, automatic door, walk through door, open door when touched
-- @about The door opens when a player bumps into it, then closes again after a few seconds.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local OPEN_TIME = 3 -- seconds the door stays open
local OPEN_TRANSPARENCY = 0.7 -- how see-through it is when open (1 = invisible)

local door = script.Parent
local closedTransparency = door.Transparency
local isOpen = false

door.Touched:Connect(function(hit)
	-- Only open for players, and not if it's already open
	if isOpen or not Players:GetPlayerFromCharacter(hit.Parent) then
		return
	end
	isOpen = true

	-- Open: you can walk through now
	door.CanCollide = false
	door.Transparency = OPEN_TRANSPARENCY

	task.wait(OPEN_TIME)

	-- Close again
	door.CanCollide = true
	door.Transparency = closedTransparency
	isOpen = false
end)
