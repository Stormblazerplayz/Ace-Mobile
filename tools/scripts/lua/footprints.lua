-- @title Footprints
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords footprints, foot steps marks, tracks in the snow, footprint trail, prints on the ground
-- @about Leaves little footprints behind walking players that slowly fade away (great for snow or sand maps).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local STEP_EVERY = 0.35 -- seconds between prints
local FADE_TIME = 6
local PRINT_COLOR = Color3.fromRGB(60, 50, 40)

local folder = Instance.new("Folder")
folder.Name = "Footprints"
folder.Parent = workspace
local leftFoot = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function stamp(player, root, humanoid)
	rayParams.FilterDescendantsInstances = { player.Character, folder }
	-- Every other step goes left, then right
	leftFoot[player] = not leftFoot[player]
	local side = leftFoot[player] and -0.5 or 0.5
	local origin = (root.CFrame * CFrame.new(side, 0, 0)).Position
	local hit = workspace:Raycast(origin, Vector3.new(0, -(humanoid.HipHeight + 4), 0), rayParams)
	if not hit then
		return
	end
	local mark = Instance.new("Part")
	mark.Size = Vector3.new(0.6, 0.05, 1)
	mark.Anchored = true
	mark.CanCollide = false
	mark.CanQuery = false
	mark.CanTouch = false
	mark.Color = PRINT_COLOR
	mark.Transparency = 0.3
	-- Lie flat on the ground facing the way the player walks
	local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	mark.CFrame = CFrame.lookAt(hit.Position, hit.Position + forward) + Vector3.new(0, 0.03, 0)
	mark.Parent = folder
	TweenService:Create(mark, TweenInfo.new(FADE_TIME), { Transparency = 1 }):Play()
	Debris:AddItem(mark, FADE_TIME)
end

while true do
	task.wait(STEP_EVERY)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local velocity = root and root.AssemblyLinearVelocity
		local walking = velocity and Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 2 and math.abs(velocity.Y) < 5
		if root and humanoid and walking then
			stamp(player, root, humanoid)
		end
	end
end
