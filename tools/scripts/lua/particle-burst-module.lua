-- @title Particle burst helper (module)
-- @category World and effects
-- @kind ModuleScript
-- @where Put this ModuleScript in ReplicatedStorage and name it Effects, then require it from any Script or LocalScript.
-- @keywords particle module, effects module, burst effect, emit particles, reusable effects
-- @about One line to make a burst of particles anywhere, like when you collect a coin or hit an enemy.

--[[ How to use it:
	local Effects = require(game.ReplicatedStorage.Effects)
	Effects.burst(somePart.Position, Color3.fromRGB(255, 220, 0), 30)  -- 30 yellow sparks
	Effects.ring(somePart.Position, Color3.new(1, 1, 1))              -- a quick flat ring of dust
]]

local Debris = game:GetService("Debris")

local Effects = {}

-- Makes an invisible part to hold the particles for a moment
local function holderAt(position)
	local holder = Instance.new("Part")
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Position = position
	holder.Parent = workspace
	Debris:AddItem(holder, 3)
	return holder
end

function Effects.burst(position, color, amount)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color or Color3.new(1, 1, 1))
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new(0.5, 0)
	emitter.Speed = NumberRange.new(10, 20)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Drag = 4
	emitter.Rate = 0
	emitter.Parent = holderAt(position)
	emitter:Emit(amount or 20)
end

function Effects.ring(position, color)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color or Color3.new(1, 1, 1))
	emitter.Size = NumberSequence.new(0.8, 0)
	emitter.Speed = NumberRange.new(15)
	emitter.SpreadAngle = Vector2.new(0, 180) -- flat circle
	emitter.EmissionDirection = Enum.NormalId.Front
	emitter.Lifetime = NumberRange.new(0.4)
	emitter.Drag = 5
	emitter.Rate = 0
	local holder = holderAt(position)
	holder.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(-90), 0, 0)
	emitter.Parent = holder
	emitter:Emit(40)
end

return Effects
