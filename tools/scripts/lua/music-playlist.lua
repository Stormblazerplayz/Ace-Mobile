-- @title Background music playlist
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and paste your music ids into SONGS (find music in the Toolbox under Audio).
-- @keywords music playlist, background music, song list, next song, game soundtrack
-- @about Plays your list of songs one after another in a shuffled order, forever, for each player.

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

-- Settings: paste your song ids here, like "rbxassetid://1234567890"
local SONGS = {
	"",
	"",
}
local VOLUME = 0.4

local player = Players.LocalPlayer

-- Remove empty entries so the script does not try to play nothing
local playlist = {}
for _, id in ipairs(SONGS) do
	if id ~= "" then
		table.insert(playlist, id)
	end
end
if #playlist == 0 then
	warn("Music playlist: add song ids to SONGS")
	return
end

local music = Instance.new("Sound")
music.Name = "PlaylistMusic"
music.Volume = VOLUME
music:SetAttribute("NormalVolume", VOLUME)
music.Parent = SoundService

-- Shuffle: mix up the order like shuffling cards
local function shuffle(list)
	for i = #list, 2, -1 do
		local j = math.random(1, i)
		list[i], list[j] = list[j], list[i]
	end
end

while true do
	shuffle(playlist)
	for _, id in ipairs(playlist) do
		music.SoundId = id
		-- Wait up to 10 seconds for the song to load (skip it if it never does)
		local waited = 0
		while not music.IsLoaded and waited < 10 do
			task.wait(0.25)
			waited += 0.25
		end
		if not music.IsLoaded then
			continue
		end
		-- Respect a "MusicMuted" setting from a settings menu
		music.Volume = player:GetAttribute("MusicMuted") and 0 or VOLUME
		music:Play()
		music.Ended:Wait()
		task.wait(1)
	end
end
