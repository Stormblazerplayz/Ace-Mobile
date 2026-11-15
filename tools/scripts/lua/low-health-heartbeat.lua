-- @title Heartbeat when health is low
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts and paste a heartbeat sound id into HEARTBEAT_ID.
-- @keywords heartbeat sound, low health warning, danger sound, near death effect, health alarm
-- @about When your health drops low you hear a heartbeat that gets faster the closer you are to zero, and the screen goes a bit gray.

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

-- Settings: change these!
local HEARTBEAT_ID = ""
local LOW = 0.3 -- below 30 percent health

local humanoid = script.Parent:WaitForChild("Humanoid")

local beat = Instance.new("Sound")
beat.SoundId = HEARTBEAT_ID
beat.Volume = 0.8
beat.Parent = SoundService

local gray = Lighting:FindFirstChild("LowHealthGray") or Instance.new("ColorCorrectionEffect")
gray.Name = "LowHealthGray"
gray.Saturation = 0
gray.Parent = Lighting

humanoid.Died:Connect(function()
	gray.Saturation = 0
	beat:Destroy()
end)

while humanoid.Health > 0 do
	local fraction = humanoid.Health / humanoid.MaxHealth
	if fraction < LOW then
		gray.Saturation = -0.8 * (1 - fraction / LOW) -- grayer as health drops
		if HEARTBEAT_ID ~= "" then
			beat:Play()
		end
		-- 1 second between beats at 30 percent, down to 0.4 at almost zero
		task.wait(0.4 + 0.6 * (fraction / LOW))
	else
		gray.Saturation = 0
		task.wait(0.5)
	end
end
