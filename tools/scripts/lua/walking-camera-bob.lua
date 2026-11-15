-- @title Camera bobs when walking
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts. Looks best in first person.
-- @keywords camera bob, head bob, walking sway, realistic camera, step bounce
-- @about The camera gently bobs up and down and side to side as you walk, faster when you run, like real footsteps.

local RunService = game:GetService("RunService")

-- Settings: change these!
local BOB_HEIGHT = 0.25
local BOB_SIDE = 0.15

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local timer = 0
local connection
connection = RunService.RenderStepped:Connect(function(deltaTime)
	if humanoid.Health <= 0 then
		humanoid.CameraOffset = Vector3.zero
		connection:Disconnect()
		return
	end
	local speed = (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
	local onGround = humanoid.FloorMaterial ~= Enum.Material.Air
	if speed > 1 and onGround then
		timer += deltaTime * speed * 0.6 -- faster steps when faster
		local up = math.abs(math.sin(timer)) * BOB_HEIGHT
		local side = math.cos(timer) * BOB_SIDE
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(Vector3.new(side, up, 0), 0.3)
	else
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(Vector3.zero, 0.1) -- settle back
	end
end)
