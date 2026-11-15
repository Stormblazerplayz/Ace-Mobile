-- @title Invisible path that appears
-- @category Obstacles
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts, then make a Folder named HiddenPath in Workspace and put your path parts inside.
-- @keywords invisible path, hidden path, secret walkway, path appears when close, invisible obby
-- @about Path parts are invisible until you walk close, then they fade in just for you.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local SHOW_DISTANCE = 12 -- studs: parts closer than this are fully visible
local FADE_DISTANCE = 20 -- studs: parts start fading in from here

local player = Players.LocalPlayer
local folder = workspace:WaitForChild("HiddenPath")

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	for _, part in ipairs(folder:GetDescendants()) do
		if part:IsA("BasePart") then
			if not root then
				part.LocalTransparencyModifier = 1
			else
				local distance = (part.Position - root.Position).Magnitude
				-- 0 = fully visible, 1 = invisible, with a smooth fade in between
				local fade = math.clamp((distance - SHOW_DISTANCE) / (FADE_DISTANCE - SHOW_DISTANCE), 0, 1)
				part.LocalTransparencyModifier = fade
			end
		end
	end
end)
