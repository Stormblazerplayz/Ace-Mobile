-- @title One-way platforms
-- @category Obstacles
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts, then make a Folder named OneWayPlatforms in Workspace and put Anchored platform Parts inside.
-- @keywords one way platform, jump up through platform, pass through from below, cloud platform, platformer jump through
-- @about You can jump up through these platforms from below and then land on top of them.

local RunService = game:GetService("RunService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local folder = workspace:WaitForChild("OneWayPlatforms")

RunService.Stepped:Connect(function()
	-- The bottom of our feet
	local feetY = root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight
	for _, platform in ipairs(folder:GetChildren()) do
		if platform:IsA("BasePart") then
			local topY = platform.Position.Y + platform.Size.Y / 2
			-- Only solid when our feet are above the top (changed just for this player)
			platform.CanCollide = feetY >= topY - 0.5
		end
	end
end)
