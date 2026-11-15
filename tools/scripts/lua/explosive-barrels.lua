-- @title Explosive barrels chain reaction
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService and tag your barrel Parts with ExplosiveBarrel (Tag Editor in the Properties window).
-- @keywords explosive barrel, barrels blow up barrels, barrels explode, red barrel, tnt barrel
-- @about Click a barrel to blow it up; any other barrel close by blows up too, then they all come back later.

local CollectionService = game:GetService("CollectionService")

-- Settings: change these numbers!
local BLAST_RADIUS = 12
local CHAIN_DELAY = 0.25 -- seconds before nearby barrels go off
local RESPAWN_TIME = 20

local function explode(barrel)
	if barrel:GetAttribute("Exploded") then
		return
	end
	barrel:SetAttribute("Exploded", true)

	local boom = Instance.new("Explosion")
	boom.Position = barrel.Position
	boom.BlastRadius = BLAST_RADIUS
	boom.DestroyJointRadiusPercent = 0.4 -- only the middle of the blast is deadly
	boom.Parent = workspace

	barrel.Transparency = 1
	barrel.CanCollide = false

	-- Set off the neighbours!
	for _, other in ipairs(CollectionService:GetTagged("ExplosiveBarrel")) do
		if other ~= barrel and (other.Position - barrel.Position).Magnitude <= BLAST_RADIUS then
			task.delay(CHAIN_DELAY, explode, other)
		end
	end

	task.delay(RESPAWN_TIME, function()
		barrel.Transparency = 0
		barrel.CanCollide = true
		barrel:SetAttribute("Exploded", nil)
	end)
end

local function setup(barrel)
	if not barrel:IsA("BasePart") then
		return
	end
	barrel.Anchored = true
	local clicker = Instance.new("ClickDetector")
	clicker.MaxActivationDistance = 40
	clicker.Parent = barrel
	clicker.MouseClick:Connect(function()
		explode(barrel)
	end)
end

for _, barrel in ipairs(CollectionService:GetTagged("ExplosiveBarrel")) do
	setup(barrel)
end
CollectionService:GetInstanceAddedSignal("ExplosiveBarrel"):Connect(setup)
