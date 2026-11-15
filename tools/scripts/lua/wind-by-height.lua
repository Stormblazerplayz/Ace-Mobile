-- @title Wind gets louder up high
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and paste a looping wind sound id into WIND_ID.
-- @keywords wind sound, height ambience, mountain wind, high altitude sound, wind volume
-- @about A wind sound that is silent near the ground and gets louder the higher you climb, great for towers and mountains.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

-- Settings: change these!
local WIND_ID = ""
local QUIET_BELOW = 50 -- height where wind starts
local LOUDEST_AT = 300 -- height where wind is loudest
local MAX_VOLUME = 0.8

if WIND_ID == "" then
	warn("Wind gets louder up high: paste a wind sound id into WIND_ID")
	return
end

local player = Players.LocalPlayer
local wind = Instance.new("Sound")
wind.SoundId = WIND_ID
wind.Looped = true
wind.Volume = 0
wind.Parent = SoundService
wind:Play()

RunService.Heartbeat:Connect(function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local fraction = math.clamp((root.Position.Y - QUIET_BELOW) / (LOUDEST_AT - QUIET_BELOW), 0, 1)
	local goal = fraction * MAX_VOLUME
	wind.Volume += (goal - wind.Volume) * 0.05 -- ease toward the goal so it never jumps
end)
