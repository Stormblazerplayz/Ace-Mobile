-- @title Invisibility pad
-- @category Players
-- @kind Script
-- @where Put this Script inside an Anchored Part that players step on.
-- @keywords invisibility, turn invisible, invisible player, vanish, ghost mode, hide from everyone
-- @about Stepping on the pad makes you invisible to everyone for a few seconds.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local INVISIBLE_TIME = 10
local COOLDOWN = 20

local pad = script.Parent
local recent = {}

local function setVisible(character, visible)
	for _, thing in ipairs(character:GetDescendants()) do
		if thing:IsA("BasePart") and thing.Name ~= "HumanoidRootPart" then
			thing.Transparency = visible and 0 or 1
		elseif thing:IsA("Decal") then -- the face
			thing.Transparency = visible and 0 or 1
		end
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Hide the name too
		humanoid.DisplayDistanceType = visible and Enum.HumanoidDisplayDistanceType.Viewer
			or Enum.HumanoidDisplayDistanceType.None
	end
end

pad.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player or recent[player] then
		return
	end
	recent[player] = true
	setVisible(character, false)
	task.wait(INVISIBLE_TIME)
	if character.Parent then
		setVisible(character, true)
	end
	task.wait(COOLDOWN - INVISIBLE_TIME)
	recent[player] = nil
end)
