-- @title Top down camera
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords top down camera, birds eye view, overhead camera, looking down camera, 2d top view
-- @about The camera floats high above your character looking straight down, like a classic top down game.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these!
local HEIGHT = 50
local TILT = 0 -- 0 = straight down; try 15 for a slight angle

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

RunService:BindToRenderStep("TopDownCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local target = root.Position
	-- Place the camera above the player, a little behind if tilted
	local offset = Vector3.new(0, HEIGHT, math.tan(math.rad(TILT)) * HEIGHT + 0.01)
	camera.CFrame = CFrame.lookAt(target + offset, target)
end)
