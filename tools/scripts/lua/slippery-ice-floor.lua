-- @title Slippery ice floor
-- @category Obstacles
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts, then set the Material of any floor part to Ice.
-- @keywords slippery ice, ice floor, sliding on ice, slide on ice, icy floor obby
-- @about Any part made of Ice becomes slippery, so players slide around and find it hard to stop.

local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local GRIP = 1.5 -- smaller = more slippery (try 0.5 to 3)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local slideVelocity = Vector3.zero -- the speed we keep while sliding

RunService.Heartbeat:Connect(function(deltaTime)
	local velocity = root.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)

	-- FloorMaterial tells us what we are standing on
	if humanoid.FloorMaterial ~= Enum.Material.Ice or humanoid.Health <= 0 then
		slideVelocity = flat -- not on ice: just remember our speed
		return
	end

	-- Where the player WANTS to go
	local wanted = humanoid.MoveDirection * humanoid.WalkSpeed
	-- Slowly turn our sliding speed toward where we want to go
	local alpha = math.clamp(GRIP * deltaTime, 0, 1)
	slideVelocity = slideVelocity:Lerp(wanted, alpha)
	root.AssemblyLinearVelocity = Vector3.new(slideVelocity.X, velocity.Y, slideVelocity.Z)
end)
