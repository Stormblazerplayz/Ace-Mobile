-- @title Field of view grows with speed
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords field of view, fov effect, speed feeling, zoom out when fast, fov stretch
-- @about The faster you move, the wider the camera view gets, so running, falling and driving feel really fast.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these!
local NORMAL_FOV = 70
local MAX_FOV = 100
local SPEED_FOR_MAX = 120 -- studs per second for the widest view

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

RunService.RenderStepped:Connect(function(deltaTime)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local speed = root and root.AssemblyLinearVelocity.Magnitude or 0
	local fraction = math.clamp((speed - 16) / (SPEED_FOR_MAX - 16), 0, 1) -- normal walking is about 16
	local goal = NORMAL_FOV + (MAX_FOV - NORMAL_FOV) * fraction
	-- Ease toward the goal so the view never jumps
	camera.FieldOfView += (goal - camera.FieldOfView) * math.min(deltaTime * 5, 1)
end)
