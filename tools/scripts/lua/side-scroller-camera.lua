-- @title Side scroller (2D) camera
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Build your level along the X direction (left and right).
-- @keywords side scroller, 2d camera, platformer camera, side view, left right only
-- @about Looks at your character from the side like a 2D platformer and keeps you on one line, so you can only run left and right and jump.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these!
local DISTANCE = 35 -- how far the camera is from the level
local HEIGHT = 4
local LANE_Z = nil -- the Z line players stay on (nil = wherever you spawn)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

RunService:BindToRenderStep("SideScroller", Enum.RenderPriority.Camera.Value + 1, function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	LANE_Z = LANE_Z or root.Position.Z
	-- Keep the character on the lane (we control our own character, so this works here)
	local p = root.Position
	if math.abs(p.Z - LANE_Z) > 0.05 then
		root.CFrame = root.CFrame + Vector3.new(0, 0, LANE_Z - p.Z)
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, v.Y, 0)
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local focus = Vector3.new(p.X, p.Y + HEIGHT, LANE_Z)
	camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, 0, DISTANCE), focus)
end)

player.CharacterAdded:Connect(function()
	LANE_Z = nil -- find the lane again after respawning
end)
