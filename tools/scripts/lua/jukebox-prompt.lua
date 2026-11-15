-- @title Jukebox everyone hears
-- @category Sound
-- @kind Script
-- @where Put this Script inside a jukebox Part (anchored), and paste song ids and names into SONGS.
-- @keywords jukebox, change the song, music machine, shared music, song request
-- @about Press E at the jukebox to switch to the next song; the music plays from the jukebox for everyone nearby, with the song name shown on top.

-- Settings: change these!
local SONGS = {
	{ name = "Song One", id = "" },
	{ name = "Song Two", id = "" },
}
local COOLDOWN = 5 -- seconds before someone can change it again

local jukebox = script.Parent

local music = Instance.new("Sound")
music.Looped = true
music.Volume = 0.6
music.RollOffMaxDistance = 120
music.Parent = jukebox

-- A sign above the jukebox shows what is playing
local sign = Instance.new("BillboardGui")
sign.Size = UDim2.fromOffset(220, 40)
sign.StudsOffset = Vector3.new(0, jukebox.Size.Y / 2 + 2, 0)
sign.Parent = jukebox
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeTransparency = 0
label.Text = "Press E for music"
label.Parent = sign

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Next song"
prompt.ObjectText = "Jukebox"
prompt.Parent = jukebox

local index = 0
local lastChange = 0
prompt.Triggered:Connect(function(player)
	if os.clock() - lastChange < COOLDOWN then
		return
	end
	lastChange = os.clock()
	index = index % #SONGS + 1
	local song = SONGS[index]
	label.Text = "Now playing: " .. song.name
	music:Stop()
	if song.id ~= "" then
		music.SoundId = song.id
		music:Play()
	end
end)
