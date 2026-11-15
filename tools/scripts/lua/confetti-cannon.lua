-- @title Confetti cannon
-- @category World and effects
-- @kind Script
-- @where Put this Script inside an Anchored Part; its top face is where the confetti shoots out.
-- @keywords confetti, confetti cannon, party popper, celebration effect, confetti burst
-- @about Step on or click the cannon to blast a burst of rainbow confetti into the air.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local PIECES = 150
local COOLDOWN = 2

local cannon = script.Parent
local attachment = Instance.new("Attachment")
attachment.Position = Vector3.new(0, cannon.Size.Y / 2, 0)
attachment.Parent = cannon

local confetti = Instance.new("ParticleEmitter")
confetti.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 90, 255)),
})
confetti.Size = NumberSequence.new(0.3)
confetti.Speed = NumberRange.new(30, 50)
confetti.SpreadAngle = Vector2.new(35, 35)
confetti.Lifetime = NumberRange.new(2, 3)
confetti.Acceleration = Vector3.new(0, -20, 0) -- falls back down
confetti.Drag = 1.5
confetti.RotSpeed = NumberRange.new(-200, 200)
confetti.Rotation = NumberRange.new(0, 360)
confetti.Rate = 0
confetti.Parent = attachment

local ready = true
local function fire()
	if not ready then
		return
	end
	ready = false
	confetti:Emit(PIECES) -- every piece comes out at once
	task.wait(COOLDOWN)
	ready = true
end

local clicker = Instance.new("ClickDetector")
clicker.Parent = cannon
clicker.MouseClick:Connect(fire)
cannon.Touched:Connect(function(hit)
	if Players:GetPlayerFromCharacter(hit.Parent) then
		fire()
	end
end)
