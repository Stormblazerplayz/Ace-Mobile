-- @title Low gravity zone
-- @category Obstacles
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts, then make a Folder named LowGravityZones in Workspace with invisible, non-colliding Parts inside.
-- @keywords low gravity, moon gravity, floaty jumps, space zone, jump higher area
-- @about Inside a low gravity zone players float down slowly and jump much higher, like on the moon.

local RunService = game:GetService("RunService")

-- Settings: change this number!
local GRAVITY_SCALE = 0.25 -- 0.25 = a quarter of normal gravity, 0 = no gravity at all

local character = script.Parent
local root = character:WaitForChild("HumanoidRootPart")
local zones = workspace:WaitForChild("LowGravityZones")

local function isInside(part, point)
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local half = part.Size / 2
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z
end

RunService.Heartbeat:Connect(function(deltaTime)
	for _, zone in ipairs(zones:GetChildren()) do
		if zone:IsA("BasePart") and isInside(zone, root.Position) then
			-- Push up a little to cancel part of the gravity pulling us down
			local lift = workspace.Gravity * (1 - GRAVITY_SCALE) * deltaTime
			root.AssemblyLinearVelocity += Vector3.new(0, lift, 0)
			return
		end
	end
end)
