-- @title Auto turret
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an anchored Part that is the turret's gun (its front face points where it shoots).
-- @keywords turret, auto turret, sentry gun, defense tower, tower shooter
-- @about The turret turns to face the nearest player in range and shoots a laser beam at them every second.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Settings: change these!
local RANGE = 70
local DAMAGE = 10
local FIRE_EVERY = 1
local SAFE_TEAM = nil -- put a team name here, like "Blue", to not shoot that team

local gun = script.Parent
gun.Anchored = true
local base = gun.Position

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { gun }

local function findTarget()
	local best, bestDistance = nil, RANGE
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local safe = SAFE_TEAM and player.Team and player.Team.Name == SAFE_TEAM
		if root and humanoid and humanoid.Health > 0 and not safe then
			local distance = (root.Position - base).Magnitude
			if distance < bestDistance then
				best, bestDistance = root, distance
			end
		end
	end
	return best
end

local function laser(from, to)
	local length = (to - from).Magnitude
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(255, 40, 40)
	beam.Size = Vector3.new(0.3, 0.3, length)
	beam.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	beam.Parent = workspace
	TweenService:Create(beam, TweenInfo.new(0.2), { Transparency = 1 }):Play()
	Debris:AddItem(beam, 0.25)
end

while true do
	local target = findTarget()
	if target then
		gun.CFrame = CFrame.lookAt(base, target.Position) -- aim
		local direction = (target.Position - base).Unit * RANGE
		local result = workspace:Raycast(base, direction, params)
		laser(base, result and result.Position or base + direction)
		if result then
			local humanoid = result.Instance.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:TakeDamage(DAMAGE)
			end
		end
	end
	task.wait(FIRE_EVERY)
end
