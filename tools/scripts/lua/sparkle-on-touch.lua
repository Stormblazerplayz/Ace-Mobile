-- @title Sparkles when touched
-- @category World and effects
-- @kind Script
-- @where Put this Script inside any Part.
-- @keywords sparkle on touch, sparkles when touched, magic sparkles, touch effect, glitter burst
-- @about Touching the part makes a burst of glittery sparkles pop out of it.

local Players = game:GetService("Players")

-- Settings: change these!
local SPARKLE_COLOR = Color3.fromRGB(255, 240, 120)
local AMOUNT = 25
local COOLDOWN = 0.5

local part = script.Parent

local sparkles = Instance.new("ParticleEmitter")
sparkles.Color = ColorSequence.new(SPARKLE_COLOR)
sparkles.LightEmission = 1
sparkles.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.2, 0.5),
	NumberSequenceKeypoint.new(1, 0),
})
sparkles.Speed = NumberRange.new(5, 12)
sparkles.SpreadAngle = Vector2.new(180, 180)
sparkles.Lifetime = NumberRange.new(0.5, 1)
sparkles.Drag = 3
sparkles.Rate = 0 -- only bursts, never a steady stream
sparkles.Parent = part

local ready = true
part.Touched:Connect(function(hit)
	if not ready or not Players:GetPlayerFromCharacter(hit.Parent) then
		return
	end
	ready = false
	sparkles:Emit(AMOUNT)
	task.wait(COOLDOWN)
	ready = true
end)
