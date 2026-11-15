-- @title Play a sound in one line (module)
-- @category Sound
-- @kind ModuleScript
-- @where Put this ModuleScript in ReplicatedStorage and name it SFX. Then in any script: require(game.ReplicatedStorage.SFX).Play("rbxassetid://123", somePart).
-- @keywords sound module, sfx helper, play sound once, sound effect helper, one shot sound
-- @about A helper that makes a sound, plays it once at a part (or everywhere), and cleans it up when it finishes.

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local SFX = {}

-- Play(id, where, volume, pitch)
--   where: a Part (sound comes from there) or nil (heard everywhere the same)
function SFX.Play(soundId, where, volume, pitch)
	if type(soundId) ~= "string" or soundId == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.6
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = where or SoundService
	sound:Play()
	-- Remove it when done (or after 30 seconds if it never ends)
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	Debris:AddItem(sound, 30)
	return sound
end

-- PlayRandomPitch: same sound but slightly different each time (great for hits and steps)
function SFX.PlayRandomPitch(soundId, where, volume)
	return SFX.Play(soundId, where, volume, 0.9 + math.random() * 0.2)
end

-- PlayAt: plays from a spot in the world, even with no part there
function SFX.PlayAt(soundId, position, volume)
	local spot = Instance.new("Part")
	spot.Anchored = true
	spot.CanCollide = false
	spot.CanQuery = false
	spot.Transparency = 1
	spot.Size = Vector3.new(1, 1, 1)
	spot.Position = position
	spot.Parent = workspace
	Debris:AddItem(spot, 30)
	return SFX.Play(soundId, spot, volume)
end

return SFX
