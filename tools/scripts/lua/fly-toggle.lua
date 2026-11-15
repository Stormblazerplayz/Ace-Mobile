-- @title Fly with a key
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords fly, flying, press f to fly, fly script, superman flight, fly mode
-- @about Press F (or the Fly button on phones) to fly where your camera points; Space goes up and Ctrl goes down.

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local FLY_SPEED = 50
local UP_DOWN_SPEED = 30

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local attachment = root:WaitForChild("RootAttachment")
local camera = workspace.CurrentCamera
local flying = false

-- LinearVelocity moves us, AlignOrientation turns us to face the camera
local mover = Instance.new("LinearVelocity")
mover.Attachment0 = attachment
mover.MaxForce = math.huge
mover.Enabled = false
mover.Parent = root
local turner = Instance.new("AlignOrientation")
turner.Mode = Enum.OrientationAlignmentMode.OneAttachment
turner.Attachment0 = attachment
turner.Responsiveness = 20
turner.MaxTorque = math.huge
turner.Enabled = false
turner.Parent = root

local function toggleFly(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	flying = not flying
	mover.Enabled = flying
	turner.Enabled = flying
	humanoid.PlatformStand = flying -- stops the walking animation fighting us
	return Enum.ContextActionResult.Sink
end
-- true = also make a button on phones and tablets
ContextActionService:BindAction("Fly", toggleFly, true, Enum.KeyCode.F)
ContextActionService:SetTitle("Fly", "Fly")

RunService.RenderStepped:Connect(function()
	if not flying then
		return
	end
	local velocity = humanoid.MoveDirection * FLY_SPEED
	-- Flying forward while looking up or down also moves you up or down
	local look = camera.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude > 0.01 then
		local forwardAmount = humanoid.MoveDirection:Dot(flatLook.Unit)
		velocity += Vector3.new(0, look.Y * FLY_SPEED * forwardAmount, 0)
		turner.CFrame = CFrame.lookAt(Vector3.zero, flatLook)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		velocity += Vector3.new(0, UP_DOWN_SPEED, 0)
	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		velocity -= Vector3.new(0, UP_DOWN_SPEED, 0)
	end
	mover.VectorVelocity = velocity
end)

humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("Fly")
end)
