-- @title Isometric camera
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords isometric camera, diagonal view, strategy game camera, angled top down, orthographic look
-- @about A far-away diagonal camera with a narrow view that makes your game look like a neat isometric strategy or puzzle game; scroll to zoom.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Settings: change these!
local ANGLE_AROUND = 45 -- degrees around the player
local ANGLE_DOWN = 35 -- degrees looking down
local FOV = 15 -- a small field of view from far away looks flat and neat
local MIN_DISTANCE, MAX_DISTANCE = 150, 500

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local distance = 250

-- Mouse wheel zooms in and out
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		distance = math.clamp(distance - input.Position.Z * 25, MIN_DISTANCE, MAX_DISTANCE)
	end
end)

RunService:BindToRenderStep("IsometricCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FOV
	local rotation = CFrame.Angles(0, math.rad(ANGLE_AROUND), 0) * CFrame.Angles(math.rad(-ANGLE_DOWN), 0, 0)
	local target = root.Position
	camera.CFrame = CFrame.new(target + rotation.LookVector * -distance) * rotation
end)
