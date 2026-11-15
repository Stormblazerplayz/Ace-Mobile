-- @title Boombox tool
-- @category Sound
-- @kind Script
-- @where Put this Script inside a Tool with a Handle, and paste song ids into SONGS. Players nearby hear it.
-- @keywords boombox, radio tool, play music tool, portable speaker, carry music
-- @about Click while holding the boombox to play the next song from your list; everyone near you can hear it.

-- Settings: paste song ids here (only songs you are allowed to use)
local SONGS = {
	"",
	"",
}

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

local music = Instance.new("Sound")
music.Name = "BoomboxMusic"
music.Volume = 0.7
music.Looped = true
music.RollOffMaxDistance = 80 -- quieter the further away you are
music.Parent = handle

local list = {}
for _, id in ipairs(SONGS) do
	if id ~= "" then
		table.insert(list, id)
	end
end

local index = 0
local lastClick = 0
tool.Activated:Connect(function()
	if #list == 0 or os.clock() - lastClick < 1 then
		return
	end
	lastClick = os.clock()
	index += 1
	if index > #list then
		-- After the last song, the next click turns the music off
		index = 0
		music:Stop()
		return
	end
	music.SoundId = list[index]
	music:Play()
end)

-- Stop playing when the boombox is put away
tool.Unequipped:Connect(function()
	music:Stop()
	index = 0
end)
