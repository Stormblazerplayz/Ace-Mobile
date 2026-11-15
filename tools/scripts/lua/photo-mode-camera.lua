-- @title Photo mode free camera
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Works on computers with a keyboard and mouse.
-- @keywords photo mode, free camera, freecam, screenshot camera, fly camera
-- @about Press P to detach the camera and fly it around with W, A, S, D, Q and E (hold right mouse to look) to take cool screenshots; press P again to go back.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

-- Settings: change these!
local SPEED = 30
local LOOK_SPEED = 0.3

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local active = false
local yaw, pitch = 0, 0
local hiddenGuis = {}

local MOVE_KEYS = {
	[Enum.KeyCode.W] = Vector3.new(0, 0, -1), [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0), [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
	[Enum.KeyCode.E] = Vector3.new(0, 1, 0), [Enum.KeyCode.Q] = Vector3.new(0, -1, 0),
}

local function sinkKeys()
	return Enum.ContextActionResult.Sink -- eat the key so the character stays still
end

local function setActive(on)
	active = on
	if on then
		local x, y = camera.CFrame:ToEulerAnglesYXZ()
		pitch, yaw = x, y
		camera.CameraType = Enum.CameraType.Scriptable
		local keys = {}
		for key in pairs(MOVE_KEYS) do
			table.insert(keys, key)
		end
		ContextActionService:BindActionAtPriority("PhotoModeKeys", sinkKeys, false, Enum.ContextActionPriority.High.Value, table.unpack(keys))
		-- Hide the GUI for a clean picture
		for _, screen in ipairs(player.PlayerGui:GetChildren()) do
			if screen:IsA("ScreenGui") and screen.Enabled then
				screen.Enabled = false
				table.insert(hiddenGuis, screen)
			end
		end
	else
		ContextActionService:UnbindAction("PhotoModeKeys")
		camera.CameraType = Enum.CameraType.Custom
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		for _, screen in ipairs(hiddenGuis) do
			screen.Enabled = true
		end
		hiddenGuis = {}
	end
end

UserInputService.InputBegan:Connect(function(input, typing)
	if not typing and input.KeyCode == Enum.KeyCode.P then
		setActive(not active)
	end
end)

RunService:BindToRenderStep("PhotoMode", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	if not active then
		return
	end
	-- Hold right mouse to look around
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		local delta = UserInputService:GetMouseDelta()
		yaw -= math.rad(delta.X * LOOK_SPEED)
		pitch = math.clamp(pitch - math.rad(delta.Y * LOOK_SPEED), -1.5, 1.5)
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	local move = Vector3.zero
	for key, direction in pairs(MOVE_KEYS) do
		if UserInputService:IsKeyDown(key) then
			move += direction
		end
	end
	local rotation = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
	local position = camera.CFrame.Position + rotation:VectorToWorldSpace(move) * SPEED * deltaTime
	camera.CFrame = CFrame.new(position) * rotation
end)
