-- @title Playable piano
-- @category Sound
-- @kind Script
-- @where Put this Script inside a piano Model. Name the key Parts 1, 2, 3... from left to right, and paste ONE piano note sound id into NOTE_ID.
-- @keywords piano, play music keys, instrument, musical keys, click to play notes
-- @about Click a key (or step on it) to play a note; each key plays a higher note than the one before it, like a real piano.

-- Settings: change these!
local NOTE_ID = "" -- a single piano note; we change its pitch for every key
local STEP_ON_KEYS = true -- also play when you walk on them

local piano = script.Parent

local function setupKey(key, number)
	local sound = Instance.new("Sound")
	sound.SoundId = NOTE_ID
	-- Each key is one half-step higher: multiply pitch by 2^(1/12) per key
	sound.PlaybackSpeed = 2 ^ ((number - 1) / 12)
	sound.Parent = key
	local normalColor = key.Color
	local lastPlay = 0

	local function play()
		if NOTE_ID == "" or os.clock() - lastPlay < 0.15 then
			return
		end
		lastPlay = os.clock()
		sound.TimePosition = 0
		sound:Play()
		-- Flash the key
		key.Color = Color3.fromRGB(255, 220, 90)
		task.delay(0.15, function()
			key.Color = normalColor
		end)
	end

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 20
	click.Parent = key
	click.MouseClick:Connect(play)
	if STEP_ON_KEYS then
		key.Touched:Connect(function(hit)
			if hit.Parent:FindFirstChildOfClass("Humanoid") then
				play()
			end
		end)
	end
end

for _, key in ipairs(piano:GetDescendants()) do
	local number = tonumber(key.Name)
	if key:IsA("BasePart") and number then
		setupKey(key, number)
	end
end
