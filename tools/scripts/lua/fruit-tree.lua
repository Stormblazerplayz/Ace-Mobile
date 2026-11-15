-- @title Fruit tree you can pick
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside a tree Model and put a Folder named Fruit inside the tree with the fruit Parts.
-- @keywords fruit tree, pick fruit, harvest apples, farming tree, fruit grows back
-- @about Press E on a fruit to pick it for coins; picked fruit slowly grows back on the tree.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local COINS_PER_FRUIT = 5
local REGROW_TIME = 30

local tree = script.Parent
local fruitFolder = tree:WaitForChild("Fruit")

local function setupFruit(fruit)
	local fullSize = fruit.Size
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick"
	prompt.ObjectText = fruit.Name
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = fruit

	prompt.Triggered:Connect(function(player)
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if coins then
			coins.Value += COINS_PER_FRUIT
		end
		-- Hide the fruit, then grow it back from tiny to full size
		prompt.Enabled = false
		fruit.Transparency = 1
		task.wait(REGROW_TIME)
		fruit.Size = fullSize * 0.1
		fruit.Transparency = 0
		local grow = TweenService:Create(fruit, TweenInfo.new(2, Enum.EasingStyle.Back), { Size = fullSize })
		grow:Play()
		grow.Completed:Wait()
		prompt.Enabled = true
	end)
end

for _, fruit in ipairs(fruitFolder:GetChildren()) do
	if fruit:IsA("BasePart") then
		setupFruit(fruit)
	end
end
