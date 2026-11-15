-- @title Camera looks at something important
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. A server script shows something with workspace:SetAttribute("CameraFocus", "BossDoor") (the name of a Part or Model in Workspace).
-- @keywords camera focus, look at event, camera pan, show the boss, point camera at object
-- @about When the server names an object, everyone's camera swoops over to look at it for a few seconds (like "the door opened!") and then swoops back.

local TweenService = game:GetService("TweenService")

-- Settings: change these!
local LOOK_TIME = 3
local DISTANCE = 25

local camera = workspace.CurrentCamera
local busy = false

workspace:GetAttributeChangedSignal("CameraFocus"):Connect(function()
	local name = workspace:GetAttribute("CameraFocus")
	local target = type(name) == "string" and workspace:FindFirstChild(name, true)
	if not target or busy then
		return
	end
	local position = target:IsA("Model") and target:GetPivot().Position or (target:IsA("BasePart") and target.Position)
	if not position then
		return
	end
	busy = true
	local startCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	-- Look from a spot above and in front of the object
	local viewFrom = position + Vector3.new(0, DISTANCE * 0.5, DISTANCE)
	local goTo = TweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(viewFrom, position) })
	goTo:Play()
	goTo.Completed:Wait()
	task.wait(LOOK_TIME)
	local goBack = TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { CFrame = startCFrame })
	goBack:Play()
	goBack.Completed:Wait()
	camera.CameraType = Enum.CameraType.Custom
	busy = false
end)
