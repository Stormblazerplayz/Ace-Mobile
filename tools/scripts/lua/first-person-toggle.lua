-- @title Switch first and third person
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords first person, third person, switch view, pov toggle, camera mode key
-- @about Press V (or tap the on-screen button on a phone) to switch between first person and the normal third person view.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local firstPerson = false

local function setFirstPerson(on)
	firstPerson = on
	if on then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		player.CameraMode = Enum.CameraMode.Classic
		-- Zoom back out a bit so you can see your character again
		player.CameraMinZoomDistance = 8
		task.wait()
		player.CameraMinZoomDistance = 0.5
	end
end

local function onAction(_, state)
	if state == Enum.UserInputState.Begin then
		task.spawn(setFirstPerson, not firstPerson) -- task.spawn: never wait inside an action callback
	end
	return Enum.ContextActionResult.Sink
end

-- true = also make a button for touch screens
ContextActionService:BindAction("ToggleView", onAction, true, Enum.KeyCode.V, Enum.KeyCode.ButtonR3)
ContextActionService:SetTitle("ToggleView", "View")
