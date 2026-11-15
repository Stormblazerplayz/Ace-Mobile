-- @title Punch combat (client part)
-- @category Tools and combat
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts and add the Punch combat (server part) Script too.
-- @keywords punch, fist fight, punch key, melee without tool, fighting game punch
-- @about Press F or click with no tool to throw a punch (with a Punch button on phones); the server decides if it hits.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: put a punch animation id here (optional)
local PUNCH_ANIMATION_ID = "" -- like "rbxassetid://123456"

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local punchEvent = ReplicatedStorage:WaitForChild("Punch")

local track
if PUNCH_ANIMATION_ID ~= "" then
	local animation = Instance.new("Animation")
	animation.AnimationId = PUNCH_ANIMATION_ID
	track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
end

local function punch(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	-- Do not punch while holding a tool (tools use the click)
	if character:FindFirstChildOfClass("Tool") then
		return Enum.ContextActionResult.Pass
	end
	if track then
		track:Play()
	end
	punchEvent:FireServer()
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("Punch", punch, true, Enum.KeyCode.F, Enum.UserInputType.MouseButton1)
ContextActionService:SetTitle("Punch", "Punch")

humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("Punch")
end)
