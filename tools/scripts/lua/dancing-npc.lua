-- @title Dancing NPC
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an R15 NPC Model (made with the Rig Builder) that is Anchored at the HumanoidRootPart or standing on the floor.
-- @keywords dancing npc, npc animation loop, play animation on npc, animator, party npc
-- @about Makes the NPC dance forever by playing Roblox's built-in dance animations one after another.

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")

-- These are Roblox's own R15 dance emotes. Swap in your own animation ids if you like!
local DANCES = {
	"rbxassetid://507771019",
	"rbxassetid://507776043",
	"rbxassetid://507777268",
}
local SWITCH_EVERY = 8 -- seconds per dance

-- An Animator loads and plays animations on the NPC
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
animator.Parent = humanoid

local tracks = {}
for _, id in ipairs(DANCES) do
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local track = animator:LoadAnimation(animation)
	track.Looped = true
	table.insert(tracks, track)
end

local current = nil
local index = 1
while humanoid.Health > 0 do
	if current then
		current:Stop(0.5) -- fade out over half a second
	end
	current = tracks[index]
	current:Play(0.5)
	index = index % #tracks + 1
	task.wait(SWITCH_EVERY)
end
