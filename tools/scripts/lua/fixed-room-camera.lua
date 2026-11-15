-- @title Fixed security-style room cameras
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Put anchored, invisible Parts in a Folder named RoomCameras in Workspace, one in a corner of each room.
-- @keywords fixed camera angles, horror camera, room corner camera, classic survival camera, cinematic angles
-- @about The camera jumps to whichever corner camera is closest and can see you, and watches you from there, like an old horror game.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cams = workspace:WaitForChild("RoomCameras")

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

-- Pick the closest camera part that has a clear line to the player
local function bestCamera(root)
	params.FilterDescendantsInstances = { cams, player.Character }
	local best, bestDistance = nil, math.huge
	for _, cam in ipairs(cams:GetChildren()) do
		if cam:IsA("BasePart") then
			local offset = root.Position - cam.Position
			if offset.Magnitude < bestDistance and not workspace:Raycast(cam.Position, offset, params) then
				best, bestDistance = cam, offset.Magnitude
			end
		end
	end
	return best
end

local current = nil
local checkTimer = 0
RunService:BindToRenderStep("FixedRoomCamera", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	checkTimer -= deltaTime
	if checkTimer <= 0 or not current then
		checkTimer = 0.25 -- do not raycast every single frame
		current = bestCamera(root) or current
	end
	if current then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(current.Position, root.Position)
	end
end)
