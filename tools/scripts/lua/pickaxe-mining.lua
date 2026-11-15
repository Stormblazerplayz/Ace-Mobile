-- @title Pickaxe and ores
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a pickaxe Tool with a Handle part, put the Tool in StarterPack, and tag ore Parts with Ore (they can have number Attributes Health and Reward).
-- @keywords pickaxe, mining, mine ores, mining simulator, break rocks, ore blocks
-- @about Swing the pickaxe at ore rocks near you to chip them down; broken ores give coins and grow back.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Settings: change these numbers!
local HIT_POWER = 1
local REACH = 6
local COOLDOWN = 0.5
local RESPAWN_TIME = 15

local tool = script.Parent
local lastSwing = 0

local function breakOre(ore, player)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		coins.Value += ore:GetAttribute("Reward") or 10
	end
	ore.Transparency = 1
	ore.CanCollide = false
	ore:SetAttribute("Broken", true)
	task.delay(RESPAWN_TIME, function()
		ore:SetAttribute("HitsLeft", nil)
		ore:SetAttribute("Broken", nil)
		ore.Transparency = 0
		ore.CanCollide = true
	end)
end

tool.Activated:Connect(function()
	local character = tool.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or os.clock() - lastSwing < COOLDOWN then
		return
	end
	lastSwing = os.clock()

	-- Play the built-in tool swing animation
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool

	-- Look for an ore just in front of the player
	local spot = root.Position + root.CFrame.LookVector * (REACH / 2)
	for _, part in ipairs(workspace:GetPartBoundsInRadius(spot, REACH / 2)) do
		if CollectionService:HasTag(part, "Ore") and not part:GetAttribute("Broken") then
			local hitsLeft = (part:GetAttribute("HitsLeft") or part:GetAttribute("Health") or 3) - HIT_POWER
			part:SetAttribute("HitsLeft", hitsLeft)
			if hitsLeft <= 0 then
				breakOre(part, player)
			end
			break -- one ore per swing
		end
	end
end)
