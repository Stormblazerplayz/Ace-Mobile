-- @title Wall jump
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords wall jump, jump off walls, kick off wall, parkour jump, wall kick
-- @about Jump while in the air next to a wall to kick off it and jump again, like in a parkour game.

local UserInputService = game:GetService("UserInputService")

-- Settings: change these numbers!
local UP_POWER = 50
local AWAY_POWER = 35
local WALL_DISTANCE = 2.5 -- how close a wall must be
local COOLDOWN = 0.3

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local lastWallJump = 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { character }

local function findWall()
	-- Look forward, back, left and right for a wall
	local cf = root.CFrame
	local directions = { cf.LookVector, -cf.LookVector, cf.RightVector, -cf.RightVector }
	for _, direction in ipairs(directions) do
		local result = workspace:Raycast(root.Position, direction * (root.Size.X / 2 + WALL_DISTANCE), rayParams)
		if result and math.abs(result.Normal.Y) < 0.3 then -- steep enough to be a wall
			return result.Normal
		end
	end
	return nil
end

UserInputService.JumpRequest:Connect(function()
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return -- only in the air
	end
	if os.clock() - lastWallJump < COOLDOWN then
		return
	end
	local normal = findWall()
	if normal then
		lastWallJump = os.clock()
		-- Push away from the wall and up
		root.AssemblyLinearVelocity = normal * AWAY_POWER + Vector3.new(0, UP_POWER, 0)
		root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(normal.X, 0, normal.Z))
	end
end)
