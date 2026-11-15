-- @title Hunger system
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService; to make food, give any Tool a number Attribute named Food (how much it fills you up).
-- @keywords hunger, hunger bar, food system, eat food, starving, get hungry over time
-- @about Players slowly get hungry, lose health when starving, and fill up by using food Tools.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local MAX_HUNGER = 100
local HUNGER_LOSS = 1 -- lost every few seconds
local LOSS_EVERY = 3 -- seconds
local STARVE_DAMAGE = 5 -- health lost each tick at 0 hunger

local function hookFood(player, tool)
	if not tool:IsA("Tool") or not tool:GetAttribute("Food") then
		return
	end
	-- Activated fires on the server when the player clicks with the tool
	tool.Activated:Connect(function()
		local hunger = player.leaderstats.Hunger
		hunger.Value = math.min(hunger.Value + tool:GetAttribute("Food"), MAX_HUNGER)
		tool:Destroy() -- eaten!
	end)
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local hunger = Instance.new("IntValue")
	hunger.Name = "Hunger"
	hunger.Value = MAX_HUNGER
	hunger.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		hunger.Value = MAX_HUNGER -- full again after respawning
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and not child:GetAttribute("HungerHooked") then
				child:SetAttribute("HungerHooked", true)
				hookFood(player, child)
			end
		end)
	end)
end)

while true do
	task.wait(LOSS_EVERY)
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = player:FindFirstChild("leaderstats")
		local hunger = stats and stats:FindFirstChild("Hunger")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hunger and humanoid and humanoid.Health > 0 then
			hunger.Value = math.max(hunger.Value - HUNGER_LOSS, 0)
			if hunger.Value == 0 then
				humanoid:TakeDamage(STARVE_DAMAGE)
			end
		end
	end
end
