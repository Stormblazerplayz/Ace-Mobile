-- @title Sparkle aura for top players
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService (needs a Wins stat in leaderstats, like from the Win pad script).
-- @keywords aura, sparkle aura, pro player effect, particles around player, aura for wins
-- @about Players with enough wins get a sparkly particle aura around them so everyone knows they are good.

local Players = game:GetService("Players")

-- Settings: change these!
local STAT_NAME = "Wins"
local WINS_NEEDED = 10
local AURA_COLOR = Color3.fromRGB(255, 230, 120)

local function updateAura(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local stats = player:FindFirstChild("leaderstats")
	local wins = stats and stats:FindFirstChild(STAT_NAME)
	if not root or not wins then
		return
	end
	local aura = root:FindFirstChild("Aura")
	if wins.Value >= WINS_NEEDED and not aura then
		aura = Instance.new("ParticleEmitter")
		aura.Name = "Aura"
		aura.Color = ColorSequence.new(AURA_COLOR)
		aura.LightEmission = 1
		aura.Size = NumberSequence.new(0.4, 0)
		aura.Lifetime = NumberRange.new(0.8, 1.2)
		aura.Rate = 25
		aura.Speed = NumberRange.new(1, 3)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Parent = root
	elseif wins.Value < WINS_NEEDED and aura then
		aura:Destroy()
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		updateAura(player)
	end)
	-- When the Wins number changes, check again
	local stats = player:WaitForChild("leaderstats", 30)
	local wins = stats and stats:WaitForChild(STAT_NAME, 30)
	if wins then
		wins.Changed:Connect(function()
			updateAura(player)
		end)
		updateAura(player)
	end
end)
