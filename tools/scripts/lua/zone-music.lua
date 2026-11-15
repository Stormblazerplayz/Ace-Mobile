-- @title Different music in each area
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Make a Folder named MusicZones in Workspace with see-through, CanCollide-off Parts; put a Sound inside each zone part.
-- @keywords zone music, area music, region soundtrack, music changes by place, biome music
-- @about When you walk into a zone, its song fades in and the old song fades out.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local zones = workspace:WaitForChild("MusicZones")
local FADE = TweenInfo.new(1.5)

-- Each zone's sound plays on this player's computer only (we move it into the player's GUI)
local zoneSounds = {}
for _, zone in ipairs(zones:GetChildren()) do
	local sound = zone:FindFirstChildOfClass("Sound")
	if sound then
		local copy = sound:Clone()
		copy.Looped = true
		copy:SetAttribute("NormalVolume", sound.Volume)
		copy.Volume = 0
		copy.Parent = player:WaitForChild("PlayerGui")
		zoneSounds[zone] = copy
	end
end

local function isInside(part, position)
	local offset = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

local currentZone = nil
while true do
	task.wait(0.5)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local newZone = nil
	if root then
		for zone in pairs(zoneSounds) do
			if isInside(zone, root.Position) then
				newZone = zone
				break
			end
		end
	end
	if newZone ~= currentZone then
		if currentZone then
			TweenService:Create(zoneSounds[currentZone], FADE, { Volume = 0 }):Play()
		end
		if newZone then
			local sound = zoneSounds[newZone]
			if not sound.IsPlaying and sound.SoundId ~= "" then
				sound:Play()
			end
			TweenService:Create(sound, FADE, { Volume = sound:GetAttribute("NormalVolume") }):Play()
		end
		currentZone = newZone
	end
end
