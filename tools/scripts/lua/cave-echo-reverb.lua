-- @title Echo inside caves
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Put see-through, CanCollide-off Parts covering your caves in a Folder named EchoZones, and give each a text Attribute named Reverb (like Cave, Hallway or Arena).
-- @keywords cave echo, reverb zone, echo room, sound reverb, big hall echo
-- @about When you walk into a cave or big hall, every sound starts to echo like it really would in there.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local zones = workspace:WaitForChild("EchoZones")
local normal = SoundService.AmbientReverb

local function isInside(part, position)
	local offset = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

-- Turn the zone's text into a ReverbType (Cave if the name is wrong)
local function reverbFor(zone)
	local name = zone:GetAttribute("Reverb") or "Cave"
	local ok, reverb = pcall(function()
		return Enum.ReverbType[name]
	end)
	return ok and reverb or Enum.ReverbType.Cave
end

while true do
	task.wait(0.5)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local wanted = normal
	if root then
		for _, zone in ipairs(zones:GetChildren()) do
			if zone:IsA("BasePart") and isInside(zone, root.Position) then
				wanted = reverbFor(zone)
				break
			end
		end
	end
	if SoundService.AmbientReverb ~= wanted then
		SoundService.AmbientReverb = wanted
	end
end
