-- @title Character grows as you level up
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService (needs a Level stat in leaderstats, like from the XP and levels script).
-- @keywords grow with level, bigger when stronger, size by level, simulator size, grow bigger
-- @about Your character gets a little bigger every level, like in a simulator game.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local STAT_NAME = "Level"
local GROW_PER_LEVEL = 0.05 -- 5 percent bigger each level
local MAX_SCALE = 3

local function resize(player)
	local character = player.Character
	local stats = player:FindFirstChild("leaderstats")
	local level = stats and stats:FindFirstChild(STAT_NAME)
	if not character or not level or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	local scale = math.clamp(1 + (level.Value - 1) * GROW_PER_LEVEL, 0.5, MAX_SCALE)
	if math.abs(character:GetScale() - scale) > 0.001 then
		character:ScaleTo(scale)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		task.wait(0.1)
		resize(player)
	end)
	local stats = player:WaitForChild("leaderstats", 30)
	local level = stats and stats:WaitForChild(STAT_NAME, 30)
	if level then
		level.Changed:Connect(function()
			resize(player)
		end)
	end
end)
