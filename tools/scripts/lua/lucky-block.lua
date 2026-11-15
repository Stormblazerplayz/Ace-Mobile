-- @title Lucky block
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside an Anchored Part (a yellow block with a question mark looks great); needs a Coins stat.
-- @keywords lucky block, random surprise, good or bad luck, mystery block, break the block
-- @about Break the block for a random surprise: coins, super speed, a big jump, or a not-so-lucky explosion!

local Players = game:GetService("Players")

-- Settings: change these numbers!
local RESPAWN_TIME = 20

local block = script.Parent
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Break"
prompt.ObjectText = "Lucky Block"
prompt.HoldDuration = 0.8
prompt.Parent = block

-- Each surprise is a little function. Add your own!
local SURPRISES = {
	function(player, humanoid)
		local coins = player.leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value += 100
		end
		return "Lucky! +100 coins"
	end,
	function(_, humanoid)
		humanoid.WalkSpeed += 20
		task.delay(10, function()
			humanoid.WalkSpeed -= 20
		end)
		return "Super speed for 10 seconds!"
	end,
	function(_, humanoid)
		local root = humanoid.Parent:FindFirstChild("HumanoidRootPart")
		if root then
			root.AssemblyLinearVelocity = Vector3.new(0, 150, 0)
		end
		return "Up, up and away!"
	end,
	function()
		local boom = Instance.new("Explosion")
		boom.Position = block.Position
		boom.BlastRadius = 8
		boom.DestroyJointRadiusPercent = 0 -- knocks you over but does not kill
		boom.Parent = workspace
		return "Unlucky... BOOM!"
	end,
}

prompt.Triggered:Connect(function(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not player:FindFirstChild("leaderstats") then
		return
	end
	prompt.Enabled = false
	block.Transparency = 1
	block.CanCollide = false
	local surprise = SURPRISES[math.random(#SURPRISES)]
	player:SetAttribute("Notice", surprise(player, humanoid))

	task.wait(RESPAWN_TIME)
	block.Transparency = 0
	block.CanCollide = true
	prompt.Enabled = true
end)
