-- @title Splash when jumping in water
-- @category World and effects
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts (works with Terrain water).
-- @keywords water splash, splash effect, jump in the water, splashing, dive splash
-- @about Makes a big splash of water drops (and a splash sound if you add one) when you land in water.

local Debris = game:GetService("Debris")

-- Settings: change these!
local SPLASH_SOUND_ID = "" -- paste a splash sound id like "rbxassetid://123456"
local DROPS = 40

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

humanoid.StateChanged:Connect(function(oldState, newState)
	-- Swimming right after falling = we just hit the water
	if newState ~= Enum.HumanoidStateType.Swimming or oldState ~= Enum.HumanoidStateType.Freefall then
		return
	end
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = root.Position + Vector3.new(0, 1, 0)
	holder.Parent = workspace

	local drops = Instance.new("ParticleEmitter")
	drops.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	drops.Transparency = NumberSequence.new(0.2, 1)
	drops.Size = NumberSequence.new(0.4, 0.1)
	drops.Speed = NumberRange.new(15, 25)
	drops.SpreadAngle = Vector2.new(40, 40)
	drops.Acceleration = Vector3.new(0, -workspace.Gravity / 3, 0)
	drops.Lifetime = NumberRange.new(0.6, 1)
	drops.EmissionDirection = Enum.NormalId.Top
	drops.Rate = 0
	drops.Parent = holder
	drops:Emit(DROPS)

	if SPLASH_SOUND_ID ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = SPLASH_SOUND_ID
		sound.Parent = holder
		sound:Play()
	end
	Debris:AddItem(holder, 2)
end)
