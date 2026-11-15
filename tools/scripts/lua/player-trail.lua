-- @title Glowing trail behind players
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords player trail, trail behind you, rainbow trail, glowing trail, speed trail
-- @about Adds a colorful glowing trail that follows behind every player as they move.

local Players = game:GetService("Players")

-- Settings: change these!
local TRAIL_LIFETIME = 0.6 -- seconds the trail lasts
local START_COLOR = Color3.fromRGB(0, 200, 255)
local END_COLOR = Color3.fromRGB(255, 0, 200)

local function onCharacterAdded(character)
	local root = character:WaitForChild("HumanoidRootPart")

	-- A trail is drawn between two attachments: one up, one down
	local top = Instance.new("Attachment")
	top.Position = Vector3.new(0, 1, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Position = Vector3.new(0, -1, 0)
	bottom.Parent = root

	local trail = Instance.new("Trail")
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = TRAIL_LIFETIME
	trail.Color = ColorSequence.new(START_COLOR, END_COLOR)
	trail.Transparency = NumberSequence.new(0.2, 1) -- fades out at the end
	trail.LightEmission = 1 -- glowy
	trail.FaceCamera = true
	trail.Parent = root
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)
