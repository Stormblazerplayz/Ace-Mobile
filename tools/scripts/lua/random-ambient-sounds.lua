-- @title Random nature sounds
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and paste ambient sound ids (birds, crickets, wind) into SOUNDS.
-- @keywords ambient sounds, nature sounds, birds chirping, random background noise, forest ambience
-- @about Every so often plays a random nature sound from a random spot around you, so your world feels alive.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: paste sound ids here
local SOUNDS = {
	"",
	"",
	"",
}
local MIN_GAP, MAX_GAP = 4, 12 -- seconds between sounds
local DISTANCE = 30 -- how far away the sound comes from

local player = Players.LocalPlayer

local list = {}
for _, id in ipairs(SOUNDS) do
	if id ~= "" then
		table.insert(list, id)
	end
end
if #list == 0 then
	warn("Random nature sounds: add sound ids to SOUNDS")
	return
end

while true do
	task.wait(math.random(MIN_GAP, MAX_GAP))
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		-- An invisible part out in the world makes the sound feel like it comes from a direction
		local angle = math.random() * math.pi * 2
		local spot = Instance.new("Part")
		spot.Anchored = true
		spot.CanCollide = false
		spot.CanQuery = false
		spot.Transparency = 1
		spot.Size = Vector3.new(1, 1, 1)
		spot.Position = root.Position + Vector3.new(math.cos(angle) * DISTANCE, math.random(0, 10), math.sin(angle) * DISTANCE)
		spot.Parent = workspace
		local sound = Instance.new("Sound")
		sound.SoundId = list[math.random(1, #list)]
		sound.Volume = 0.3 + math.random() * 0.3
		sound.PlaybackSpeed = 0.9 + math.random() * 0.2
		sound.RollOffMaxDistance = 100
		sound.Parent = spot
		sound:Play()
		Debris:AddItem(spot, 15)
	end
end
