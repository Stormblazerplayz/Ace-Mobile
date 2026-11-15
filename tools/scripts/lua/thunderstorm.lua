-- @title Thunderstorm flashes
-- @category World and effects
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts (use it with the Rain script and the Weather changer).
-- @keywords thunderstorm, lightning flash, thunder sound, stormy sky, flashing sky
-- @about When the Weather attribute on Workspace is Storm, the sky goes dark and flashes with lightning and thunder.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- Settings: change these!
local THUNDER_SOUND_ID = "" -- paste a thunder sound id like "rbxassetid://123456"
local MIN_GAP, MAX_GAP = 5, 15 -- seconds between flashes

-- A ColorCorrection lets us darken and flash the whole screen
local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "StormGrade"
grade.Parent = Lighting

local thunder = Instance.new("Sound")
thunder.SoundId = THUNDER_SOUND_ID
thunder.Volume = 0.8
thunder.Parent = workspace.CurrentCamera

local function isStorm()
	return workspace:GetAttribute("Weather") == "Storm"
end

local function flash()
	grade.Brightness = 0.6
	task.wait(0.05)
	grade.Brightness = -0.15
	task.wait(0.08)
	grade.Brightness = 0.4
	TweenService:Create(grade, TweenInfo.new(0.4), { Brightness = -0.15 }):Play()
	-- Thunder comes a moment after the flash, like real life!
	task.delay(math.random() * 1.5 + 0.3, function()
		if THUNDER_SOUND_ID ~= "" then
			thunder.PlaybackSpeed = 0.8 + math.random() * 0.4
			thunder:Play()
		end
	end)
end

while true do
	if isStorm() then
		grade.Brightness = -0.15 -- darker sky
		grade.Saturation = -0.3
		task.wait(math.random(MIN_GAP, MAX_GAP))
		if isStorm() then
			flash()
		end
	else
		grade.Brightness = 0
		grade.Saturation = 0
		task.wait(1)
	end
end
