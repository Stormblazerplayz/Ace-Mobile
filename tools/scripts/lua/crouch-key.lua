-- @title Crouch key
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts (optional: paste a crouch animation id below).
-- @keywords crouch, press c to crouch, sneak, duck down, crouch walk, sneaking
-- @about Press C (or the Crouch button on phones) to crouch: you move slower and your camera goes lower.

local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

-- Settings: change these!
local CROUCH_SPEED = 8
local CAMERA_DROP = 1.5 -- how many studs the camera goes down
local CROUCH_ANIMATION_ID = "" -- like "rbxassetid://1234567" (leave empty for no animation)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local normalSpeed = humanoid.WalkSpeed
local crouching = false

local track
if CROUCH_ANIMATION_ID ~= "" then
	local animation = Instance.new("Animation")
	animation.AnimationId = CROUCH_ANIMATION_ID
	track = animator:LoadAnimation(animation)
	track.Looped = true
end

local function setCrouch(on)
	crouching = on
	humanoid.WalkSpeed = on and CROUCH_SPEED or normalSpeed
	local offset = on and Vector3.new(0, -CAMERA_DROP, 0) or Vector3.zero
	TweenService:Create(humanoid, TweenInfo.new(0.2), { CameraOffset = offset }):Play()
	if track then
		if on then track:Play() else track:Stop() end
	end
end

ContextActionService:BindAction("Crouch", function(_, state)
	if state == Enum.UserInputState.Begin then
		setCrouch(not crouching)
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.C)
ContextActionService:SetTitle("Crouch", "Crouch")

humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("Crouch")
end)
