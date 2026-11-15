-- @title Axe that chops trees
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside an axe Tool with a Handle part, put the Tool in StarterPack, and tag your tree Models with Tree (move each tree's Pivot to the bottom of its trunk so it tips over nicely).
-- @keywords axe, chop trees, wood cutting, lumber, collect wood, timber
-- @about Swing the axe next to a tree to chop it; after a few hits it falls over, gives Wood and grows back later.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local HITS_TO_FELL = 4
local WOOD_PER_TREE = 5
local REACH = 7
local REGROW_TIME = 30

local tool = script.Parent
local lastSwing = 0

local function giveWood(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local wood = stats:FindFirstChild("Wood")
	if not wood then
		wood = Instance.new("IntValue")
		wood.Name = "Wood"
		wood.Parent = stats
	end
	wood.Value += WOOD_PER_TREE
end

local function fell(tree, player)
	tree:SetAttribute("Fallen", true)
	giveWood(player)
	local standing = tree:GetPivot()
	-- Tip the tree over with a tween on a CFrameValue
	local value = Instance.new("CFrameValue")
	value.Value = standing
	value.Changed:Connect(function(cf)
		tree:PivotTo(cf)
	end)
	TweenService:Create(value, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = standing * CFrame.Angles(0, 0, math.rad(85)) }):Play()
	task.delay(REGROW_TIME, function()
		value:Destroy()
		tree:PivotTo(standing)
		tree:SetAttribute("Fallen", nil)
		tree:SetAttribute("Chops", nil)
	end)
end

tool.Activated:Connect(function()
	local character = tool.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or os.clock() - lastSwing < 0.6 then
		return
	end
	lastSwing = os.clock()
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool

	for _, tree in ipairs(CollectionService:GetTagged("Tree")) do
		if tree:IsA("Model") and not tree:GetAttribute("Fallen") then
			local distance = (tree:GetPivot().Position - root.Position) * Vector3.new(1, 0, 1)
			if distance.Magnitude <= REACH then
				local chops = (tree:GetAttribute("Chops") or 0) + 1
				tree:SetAttribute("Chops", chops)
				if chops >= HITS_TO_FELL then
					fell(tree, player)
				end
				break
			end
		end
	end
end)
