-- @title Smooth music changes (module)
-- @category Sound
-- @kind ModuleScript
-- @where Put this ModuleScript in ReplicatedStorage and name it MusicFader. In a LocalScript: require(game.ReplicatedStorage.MusicFader).PlaySong("rbxassetid://123").
-- @keywords crossfade, fade music, switch song smoothly, music fader, blend songs
-- @about Switches songs by fading the old one out while the new one fades in, so music never cuts off suddenly.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local MusicFader = {}
MusicFader.Volume = 0.5
MusicFader.FadeTime = 2

local current = nil

-- PlaySong(id): fades to this song. Calling it with the same song does nothing.
function MusicFader.PlaySong(soundId)
	if current and current.SoundId == soundId then
		return
	end
	local old = current
	if old then
		local fadeOut = TweenService:Create(old, TweenInfo.new(MusicFader.FadeTime), { Volume = 0 })
		fadeOut:Play()
		fadeOut.Completed:Once(function()
			old:Destroy()
		end)
	end
	if not soundId or soundId == "" then
		current = nil -- an empty id means fade to silence
		return
	end
	local new = Instance.new("Sound")
	new.SoundId = soundId
	new.Looped = true
	new.Volume = 0
	new.Parent = SoundService
	new:Play()
	TweenService:Create(new, TweenInfo.new(MusicFader.FadeTime), { Volume = MusicFader.Volume }):Play()
	current = new
end

-- Stop(): fade out to silence
function MusicFader.Stop()
	MusicFader.PlaySong(nil)
end

return MusicFader
