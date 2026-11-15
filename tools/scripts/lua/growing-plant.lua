-- @title Plant that grows in stages
-- @category World and effects
-- @kind Script
-- @where Put this Script inside an Anchored Part sitting on the ground (the plant).
-- @keywords growing plant, plant grows over time, farming crop, harvest crops, grow a plant
-- @about The plant grows bigger in stages and turns green, then can be harvested for coins and starts again as a seed.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local STAGES = 4
local SECONDS_PER_STAGE = 10
local HARVEST_COINS = 20

local plant = script.Parent
plant.Anchored = true
local fullSize = plant.Size
local bottomY = plant.Position.Y - fullSize.Y / 2 -- keep the bottom on the ground

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Harvest"
prompt.ObjectText = "Plant"
prompt.Enabled = false
prompt.Parent = plant

local function setStage(stage)
	local fraction = stage / STAGES
	local size = fullSize * math.max(fraction, 0.15)
	local goal = {
		Size = size,
		Position = Vector3.new(plant.Position.X, bottomY + size.Y / 2, plant.Position.Z),
		Color = Color3.fromRGB(140, 110, 70):Lerp(Color3.fromRGB(60, 200, 70), fraction),
	}
	TweenService:Create(plant, TweenInfo.new(1, Enum.EasingStyle.Back), goal):Play()
end

local function grow()
	for stage = 0, STAGES do
		setStage(stage)
		if stage < STAGES then
			task.wait(SECONDS_PER_STAGE)
		end
	end
	prompt.Enabled = true -- ready to harvest!
end

prompt.Triggered:Connect(function(player)
	prompt.Enabled = false
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		coins.Value += HARVEST_COINS
	end
	task.spawn(grow)
end)

grow()
