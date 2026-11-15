-- @title Camera shake (module)
-- @category Camera
-- @kind ModuleScript
-- @where Put this ModuleScript in ReplicatedStorage and name it CameraShake. In a LocalScript: require(game.ReplicatedStorage.CameraShake).Shake(1, 0.5).
-- @keywords camera shake, screen shake, shake effect, explosion shake, impact shake
-- @about Shakes the player's camera for a moment (great for explosions, hits and landings), fading out smoothly.

local RunService = game:GetService("RunService")

local CameraShake = {}

local strength = 0
local timeLeft = 0
local totalTime = 1
local bound = false

local function bind()
	if bound then
		return
	end
	bound = true
	-- Run right after Roblox moves the camera, and add a small wobble on top
	RunService:BindToRenderStep("CameraShake", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		if timeLeft <= 0 then
			return
		end
		timeLeft -= deltaTime
		local fade = math.max(timeLeft / totalTime, 0) -- 1 at the start, 0 at the end
		local power = strength * fade
		local t = os.clock() * 25
		-- math.noise gives smooth random wiggles
		local x = math.noise(t, 0.5) * power
		local y = math.noise(0.5, t) * power
		local roll = math.noise(t, t) * power * 0.05
		local camera = workspace.CurrentCamera
		camera.CFrame = camera.CFrame * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, roll)
	end)
end

-- Shake(power, seconds): power 0.5 is gentle, 2 is huge
function CameraShake.Shake(power, seconds)
	bind()
	-- A stronger shake replaces a weaker one that is still going
	if power >= strength * math.max(timeLeft / totalTime, 0) then
		strength = power
		totalTime = math.max(seconds or 0.5, 0.05)
		timeLeft = totalTime
	end
end

return CameraShake
