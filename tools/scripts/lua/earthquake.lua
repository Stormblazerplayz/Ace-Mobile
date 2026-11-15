-- @title Earthquake
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService; unanchored parts in a Folder named Shakeable in Workspace get thrown around too.
-- @keywords earthquake, ground shakes, quake event, screen shake disaster, everything shakes
-- @about Every few minutes the ground rumbles: everyone's camera shakes and loose objects bounce around.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local QUAKE_EVERY = 240 -- seconds between earthquakes
local QUAKE_TIME = 8 -- how long each one lasts
local SHAKE_STRENGTH = 0.6 -- camera shake (studs)

local shakeable = workspace:FindFirstChild("Shakeable")

local function setCameraShake(strength)
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- CameraOffset moves the player's camera a little; random values every tick = shaking
			humanoid.CameraOffset = Vector3.new(
				(math.random() - 0.5) * strength,
				(math.random() - 0.5) * strength,
				(math.random() - 0.5) * strength
			)
		end
	end
end

while true do
	task.wait(QUAKE_EVERY)
	workspace:SetAttribute("Earthquake", true)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Notice", "EARTHQUAKE!")
	end
	local stop = os.clock() + QUAKE_TIME
	while os.clock() < stop do
		setCameraShake(SHAKE_STRENGTH)
		if shakeable then
			for _, part in ipairs(shakeable:GetDescendants()) do
				if part:IsA("BasePart") and not part.Anchored then
					local push = Vector3.new(math.random(-10, 10), math.random(5, 15), math.random(-10, 10))
					part:ApplyImpulse(push * part.AssemblyMass)
				end
			end
		end
		task.wait(0.1)
	end
	setCameraShake(0)
	workspace:SetAttribute("Earthquake", false)
end
