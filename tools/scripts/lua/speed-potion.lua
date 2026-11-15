-- @title Speed potion
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part and give the Tool to players (StarterPack or a shop).
-- @keywords speed potion, drink for speed, speed boost item, haste potion, fast potion
-- @about Drink the potion to run super fast with a sparkly trail for a while; it is used up after one drink.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local SPEED_MULTIPLIER = 2
local BOOST_TIME = 15

local tool = script.Parent
local used = false

tool.Activated:Connect(function()
	local character = tool.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if used or not Players:GetPlayerFromCharacter(character) or not humanoid or not root then
		return
	end
	used = true
	tool.Parent = nil -- the bottle disappears right away

	local normalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = normalSpeed * SPEED_MULTIPLIER

	-- Sparkles so everyone can see you are boosted
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(Color3.fromRGB(120, 220, 255))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.3, 0)
	sparkles.Lifetime = NumberRange.new(0.5)
	sparkles.Rate = 30
	sparkles.Speed = NumberRange.new(1)
	sparkles.Parent = root

	task.wait(BOOST_TIME)
	if humanoid.Parent then
		humanoid.WalkSpeed = normalSpeed
	end
	sparkles:Destroy()
	tool:Destroy()
end)
