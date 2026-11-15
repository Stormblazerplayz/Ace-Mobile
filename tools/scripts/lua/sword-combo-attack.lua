-- @title Sword with 3-hit combo
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part (the sword) and put the Tool in StarterPack (use this instead of the Basic sword script).
-- @keywords sword combo, combo attack, three hit combo, finisher hit, combo sword
-- @about Click quickly to chain three swings; each hit in the combo does more damage and the last one knocks enemies back.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: damage for hit 1, 2 and 3 of the combo
local COMBO_DAMAGE = { 10, 15, 25 }
local COMBO_WINDOW = 0.8 -- seconds you have to click again to keep the combo going
local SWING_COOLDOWN = 0.35
local REACH = 5
local FINISHER_KNOCKBACK = 60

local tool = script.Parent
local comboStep = 0
local lastSwing = 0

tool.Activated:Connect(function()
	local character = tool.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local now = os.clock()
	if not player or not root or now - lastSwing < SWING_COOLDOWN then
		return
	end
	-- Keep the combo going if we clicked in time, otherwise start over
	if now - lastSwing > COMBO_WINDOW or comboStep >= #COMBO_DAMAGE then
		comboStep = 0
	end
	comboStep += 1
	lastSwing = now

	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = comboStep == #COMBO_DAMAGE and "Lunge" or "Slash"
	anim.Parent = tool

	-- Hitbox: a box in front of the player
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = {}
	for _, part in ipairs(workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, 0, -REACH / 2 - 1), Vector3.new(5, 5, REACH), params)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local enemy = model and model:FindFirstChildOfClass("Humanoid")
		local victim = model and Players:GetPlayerFromCharacter(model)
		local teammate = victim and victim.Team and victim.Team == player.Team and not player.Neutral
		if enemy and enemy.Health > 0 and not hit[enemy] and not teammate then
			hit[enemy] = true
			local tag = Instance.new("ObjectValue")
			tag.Name = "creator"
			tag.Value = player
			tag.Parent = enemy
			Debris:AddItem(tag, 2)
			enemy:TakeDamage(COMBO_DAMAGE[comboStep])
			-- The last hit of the combo sends them flying
			local enemyRoot = model:FindFirstChild("HumanoidRootPart")
			if comboStep == #COMBO_DAMAGE and enemyRoot then
				enemyRoot.AssemblyLinearVelocity = root.CFrame.LookVector * FINISHER_KNOCKBACK + Vector3.new(0, 25, 0)
			end
		end
	end
	tool:SetAttribute("Combo", comboStep) -- a GUI can show the combo number
end)
