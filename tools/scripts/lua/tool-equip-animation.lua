-- @title Tool hold and attack animations
-- @category Tools and combat
-- @kind LocalScript
-- @where Put this LocalScript inside any Tool and paste your own animation ids below.
-- @keywords tool animation, hold animation, attack animation, custom tool pose, play animation when equipped
-- @about Plays your own holding pose while the tool is out and an attack animation each time you click.

-- Settings: paste animation ids you made (leave one empty to skip it)
local HOLD_ANIMATION_ID = "" -- like "rbxassetid://123456"
local ATTACK_ANIMATION_ID = ""

local tool = script.Parent
local holdTrack, attackTrack

local function load(character, id, priority, looped)
	if id == "" then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local track = animator:LoadAnimation(animation)
	track.Priority = priority
	track.Looped = looped
	return track
end

tool.Equipped:Connect(function()
	local character = tool.Parent
	-- Load once, then reuse (loading again and again wastes memory)
	if not holdTrack and HOLD_ANIMATION_ID ~= "" then
		holdTrack = load(character, HOLD_ANIMATION_ID, Enum.AnimationPriority.Idle, true)
	end
	if not attackTrack and ATTACK_ANIMATION_ID ~= "" then
		attackTrack = load(character, ATTACK_ANIMATION_ID, Enum.AnimationPriority.Action, false)
	end
	if holdTrack then
		holdTrack:Play(0.2)
	end
end)

tool.Unequipped:Connect(function()
	if holdTrack then
		holdTrack:Stop(0.2)
	end
end)

tool.Activated:Connect(function()
	if attackTrack and not attackTrack.IsPlaying then
		attackTrack:Play(0.05)
	end
end)

