-- @title Emote hotkeys
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts and paste your animation ids into the list.
-- @keywords emote keys, dance hotkeys, press 1 to dance, play animation on key, emotes
-- @about Press 1, 2, 3 or 4 to play a dance or emote animation; moving stops it.

local UserInputService = game:GetService("UserInputService")

-- Settings: put your own animation ids here (animations must be owned by you or your group)
local EMOTES = {
	[Enum.KeyCode.One] = "rbxassetid://507771019", -- Roblox dance 1
	[Enum.KeyCode.Two] = "rbxassetid://507776043", -- Roblox dance 2
	[Enum.KeyCode.Three] = "rbxassetid://507777268", -- Roblox dance 3
	[Enum.KeyCode.Four] = "rbxassetid://507770239", -- Roblox wave
}

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

-- Load every animation once so they start instantly
local tracks = {}
for key, id in pairs(EMOTES) do
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	tracks[key] = animator:LoadAnimation(animation)
	tracks[key].Priority = Enum.AnimationPriority.Action
end

local playing = nil

UserInputService.InputBegan:Connect(function(input, typing)
	if typing then
		return -- do not dance while typing in chat!
	end
	local track = tracks[input.KeyCode]
	if not track then
		return
	end
	if playing then
		playing:Stop()
	end
	if playing == track then
		playing = nil -- pressing the same key again stops it
	else
		track:Play()
		playing = track
	end
end)

-- Walking cancels the emote
humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
	if playing and humanoid.MoveDirection.Magnitude > 0 then
		playing:Stop()
		playing = nil
	end
end)
