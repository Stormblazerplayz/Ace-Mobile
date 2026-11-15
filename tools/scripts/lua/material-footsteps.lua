-- @title Footstep sounds by floor type
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts and paste footstep sound ids into STEP_SOUNDS.
-- @keywords footstep sounds, floor material sounds, walking sounds, grass steps, step noise
-- @about Plays a different footstep sound for grass, wood, metal, sand and more, faster when you run.

local SoundService = game:GetService("SoundService")

-- Settings: one sound id per floor material ("" means use the Default one)
local STEP_SOUNDS = {
	Default = "",
	Grass = "",
	Wood = "",
	WoodPlanks = "",
	Metal = "",
	DiamondPlate = "",
	Sand = "",
	Snow = "",
}

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- Turn down Roblox's own running sound so the two do not overlap
local defaultRunning = root:WaitForChild("Running", 5)
if defaultRunning and defaultRunning:IsA("Sound") then
	defaultRunning.Volume = 0
end

local step = Instance.new("Sound")
step.Volume = 0.6
step.Parent = root

while humanoid.Health > 0 do
	local speed = (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
	local material = humanoid.FloorMaterial
	if speed > 2 and material ~= Enum.Material.Air then
		local id = STEP_SOUNDS[material.Name]
		if not id or id == "" then
			id = STEP_SOUNDS.Default
		end
		if id ~= "" then
			step.SoundId = id
			step.PlaybackSpeed = 0.9 + math.random() * 0.2 -- tiny changes sound more natural
			step:Play()
		end
		-- Faster walking means faster steps
		task.wait(math.clamp(5 / speed, 0.2, 0.5))
	else
		task.wait(0.1)
	end
end
