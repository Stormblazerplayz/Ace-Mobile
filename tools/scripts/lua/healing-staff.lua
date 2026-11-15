-- @title Healing staff for teammates
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part (the staff) and put the Tool in StarterPack.
-- @keywords healing staff, heal teammates, medic tool, support healer, area heal
-- @about Click to send out a wave of healing that heals you and every teammate close by.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local HEAL_AMOUNT = 25
local RADIUS = 15
local COOLDOWN = 5

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local lastHeal = 0

local glow = Instance.new("ParticleEmitter")
glow.Color = ColorSequence.new(Color3.fromRGB(100, 255, 140))
glow.LightEmission = 1
glow.Size = NumberSequence.new(0.6, 0)
glow.Speed = NumberRange.new(10, 15)
glow.SpreadAngle = Vector2.new(180, 180)
glow.Lifetime = NumberRange.new(0.6)
glow.Rate = 0
glow.Parent = handle

local function sameTeam(a, b)
	-- With no teams in the game, everyone counts as a friend
	return a.Neutral or b.Neutral or a.Team == b.Team
end

tool.Activated:Connect(function()
	local character = tool.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or os.clock() - lastHeal < COOLDOWN then
		return
	end
	lastHeal = os.clock()
	glow:Emit(60)

	for _, other in ipairs(Players:GetPlayers()) do
		local theirCharacter = other.Character
		local theirRoot = theirCharacter and theirCharacter:FindFirstChild("HumanoidRootPart")
		local humanoid = theirCharacter and theirCharacter:FindFirstChildOfClass("Humanoid")
		if theirRoot and humanoid and humanoid.Health > 0 and sameTeam(player, other)
			and (theirRoot.Position - root.Position).Magnitude <= RADIUS then
			humanoid.Health = math.min(humanoid.Health + HEAL_AMOUNT, humanoid.MaxHealth)
		end
	end
end)
